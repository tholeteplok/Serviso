import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/wo_status.dart';
import '../../auth/models/profile.dart';
import '../models/payment.dart';
import '../models/work_order.dart';
import 'repository_exception.dart';

abstract class WorkOrderRepository {
  Stream<List<WorkOrder>> watchBoard();

  Future<WorkOrder?> getById(String id);

  Future<WorkOrder> create(WorkOrderDraft draft);

  Future<void> start(String id);

  Future<void> complete(String id);

  Future<void> cancel(String id);

  Future<void> pay({
    required String id,
    required double paidAmount,
    required PaymentMethod payMethod,
  });

  Future<void> addItem(String id, WoItemInput item);

  Future<void> removeItem(String id, String itemId);

  Future<void> updateDetail({
    required String id,
    String? complaint,
    String? diagnosis,
    String? techNote,
  });

  Future<List<Profile>> listTechnicians();
}

class SupabaseWorkOrderRepository implements WorkOrderRepository {
  SupabaseWorkOrderRepository(this._client);

  final SupabaseClient _client;

  static const _boardColumns =
      '*, vehicles(plate_no, brand, model, customers(name)), assignee:assigned_to(full_name)';

  static const _detailColumns =
      '*, vehicles(plate_no, brand, model, customers(name)), assignee:assigned_to(full_name), wo_items(*, parts(name, code))';

  Future<List<WorkOrder>> _fetchBoard() async {
    final result = await _client
        .from('work_orders')
        .select(_boardColumns)
        .order('created_at', ascending: false);
    return (result as List)
        .map((m) => WorkOrder.fromBoardMap(m))
        .toList();


  }

  @override
  Stream<List<WorkOrder>> watchBoard() {
    final controller = StreamController<List<WorkOrder>>.broadcast();
    bool closed = false;

    Future<void> fetch() async {
      try {
        final orders = await _fetchBoard();
        if (!closed && !controller.isClosed) controller.add(orders);
      } catch (e) {
        if (!closed && !controller.isClosed) {
          controller.addError(RepositoryException(mapRepositoryError(e)));
        }
      }
    }

    fetch();

    final channel = _client
        .channel('work_orders_board')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'work_orders',
          callback: (_) => fetch(),
        )
        .subscribe();

    controller.onCancel = () {
      closed = true;
      _client.removeChannel(channel);
      if (!controller.isClosed) controller.close();
    };

    return controller.stream;
  }

  @override
  Future<WorkOrder?> getById(String id) async {
    try {
      final data = await _client
          .from('work_orders')
          .select(_detailColumns)
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return WorkOrder.fromDetailMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<WorkOrder> create(WorkOrderDraft draft) async {
    try {
      final created = await _client
          .from('work_orders')
          .insert(draft.toInsertMap())
          .select(_detailColumns)
          .single();
      final order = WorkOrder.fromDetailMap(created);
      if (draft.items.isNotEmpty) {
        await _client.from('wo_items').insert(
              draft.items.map((i) => i.toInsertMap(order.id)).toList(),
            );
      }
      return getById(order.id).then((v) => v!);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  Future<WoStatus> _currentStatus(String id) async {
    final data = await _client
        .from('work_orders')
        .select('status')
        .eq('id', id)
        .single();
    return _statusFromString((data as Map)['status'] as String?);
  }

  @override
  Future<void> start(String id) async {
    try {
      final status = await _currentStatus(id);
      if (status != WoStatus.menunggu) {
        throw const RepositoryException(
          'Work order hanya bisa dimulai dari status Menunggu',
        );
      }
      await _client
          .from('work_orders')
          .update({'status': 'dikerjakan', 'started_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> complete(String id) async {
    try {
      await _client.rpc(
        'complete_work_order',
        params: {'p_work_order_id': id},
      );
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> cancel(String id) async {
    try {
      final status = await _currentStatus(id);
      if (status == WoStatus.menunggu) {
        await _client.from('work_orders').update({
          'status': 'dibatalkan',
          'cancelled_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      } else {
        await _client.rpc(
          'cancel_work_order',
          params: {'p_work_order_id': id},
        );
      }
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> pay({
    required String id,
    required double paidAmount,
    required PaymentMethod payMethod,
  }) async {
    try {
      final status = await _currentStatus(id);
      if (status != WoStatus.selesai) {
        throw const RepositoryException('Pembayaran hanya untuk work order yang sudah selesai');
      }
      if (paidAmount.isNaN || paidAmount.isInfinite || paidAmount < 0) {
        throw const RepositoryException('Nominal pembayaran tidak valid');
      }
      final order = await getById(id);
      final total = order?.total ?? 0;
      if (total > 0 && paidAmount < total) {
        throw const RepositoryException('Nominal kurang dari total tagihan');
      }
      await _client.from('work_orders').update({
        'paid_amount': paidAmount,
        'pay_method': payMethod.value,
        'paid_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> addItem(String id, WoItemInput item) async {
    try {
      final status = await _currentStatus(id);
      if (status != WoStatus.menunggu && status != WoStatus.dikerjakan) {
        throw const RepositoryException(
          'Item hanya bisa ditambah saat work order Menunggu atau Dikerjakan',
        );
      }
      await _client.from('wo_items').insert(item.toInsertMap(id));
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> removeItem(String id, String itemId) async {
    try {
      final status = await _currentStatus(id);
      if (status != WoStatus.menunggu && status != WoStatus.dikerjakan) {
        throw const RepositoryException(
          'Item hanya bisa dihapus saat work order Menunggu atau Dikerjakan',
        );
      }
      await _client.from('wo_items').delete().eq('id', itemId);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> updateDetail({
    required String id,
    String? complaint,
    String? diagnosis,
    String? techNote,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (complaint != null) {
        updates['complaint'] =
            complaint.trim().isEmpty ? null : complaint.trim();
      }
      if (diagnosis != null) updates['diagnosis'] = diagnosis.trim();
      if (techNote != null) updates['tech_note'] = techNote.trim();
      await _client.from('work_orders').update(updates).eq('id', id);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<Profile>> listTechnicians() async {
    try {
      final result = await _client
          .from('profiles')
          .select('id, full_name, role')
          .order('full_name');
      return (result as List)
          .map((m) => Profile.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }
}

WoStatus _statusFromString(String? value) {
  switch (value) {
    case 'menunggu':
      return WoStatus.menunggu;
    case 'dikerjakan':
      return WoStatus.dikerjakan;
    case 'selesai':
      return WoStatus.selesai;
    case 'dibatalkan':
      return WoStatus.dibatalkan;
    default:
      return WoStatus.menunggu;
  }
}
