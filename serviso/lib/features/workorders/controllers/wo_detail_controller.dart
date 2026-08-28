import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository_exception.dart';
import '../../../core/models/wo_status.dart';
import '../logic/wo_state_machine.dart';
import '../models/payment.dart';
import '../models/work_order.dart';
import 'work_order_providers.dart';

class WoDetailController
    extends AutoDisposeFamilyAsyncNotifier<WorkOrder, String> {
  @override
  Future<WorkOrder> build(String arg) async {
    final repo = ref.watch(workOrderRepositoryProvider);
    final order = await repo.getById(arg);
    if (order == null) {
      throw const RepositoryException('Work order tidak ditemukan');
    }
    return order;
  }

  Future<void> start() async {
    final repo = ref.read(workOrderRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null ||
        !WoStateMachine.canTransition(current.status, WoEvent.start)) {
      throw const RepositoryException('Transisi status tidak diizinkan');
    }
    await repo.start(arg);
    await _reload();
  }

  Future<void> complete() async {
    final repo = ref.read(workOrderRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null ||
        !WoStateMachine.canTransition(current.status, WoEvent.complete)) {
      throw const RepositoryException('Transisi status tidak diizinkan');
    }
    await repo.complete(arg);
    await _reload();
  }

  Future<void> cancel() async {
    final repo = ref.read(workOrderRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null ||
        !WoStateMachine.canTransition(current.status, WoEvent.cancel)) {
      throw const RepositoryException('Transisi status tidak diizinkan');
    }
    await repo.cancel(arg);
    await _reload();
  }

  Future<void> pay({
    required double paidAmount,
    required PaymentMethod payMethod,
  }) async {
    final repo = ref.read(workOrderRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null || current.status != WoStatus.selesai) {
      throw const RepositoryException(
        'Pembayaran hanya untuk work order yang sudah selesai',
      );
    }
    await repo.pay(
      id: arg,
      paidAmount: paidAmount,
      payMethod: payMethod,
    );
    await _reload();
  }

  Future<void> addItem(WoItemInput item) async {
    final repo = ref.read(workOrderRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null ||
        (current.status != WoStatus.menunggu && current.status != WoStatus.dikerjakan)) {
      throw const RepositoryException(
        'Item hanya bisa ditambah saat status Menunggu atau Dikerjakan',
      );
    }
    await repo.addItem(arg, item);
    await _reload();
  }

  Future<void> removeItem(String itemId) async {
    final repo = ref.read(workOrderRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null ||
        (current.status != WoStatus.menunggu && current.status != WoStatus.dikerjakan)) {
      throw const RepositoryException(
        'Item hanya bisa dihapus saat status Menunggu atau Dikerjakan',
      );
    }
    await repo.removeItem(arg, itemId);
    await _reload();
  }

  Future<void> updateDetail({
    String? complaint,
    String? diagnosis,
    String? techNote,
  }) async {
    final repo = ref.read(workOrderRepositoryProvider);
    await repo.updateDetail(
      id: arg,
      complaint: complaint,
      diagnosis: diagnosis,
      techNote: techNote,
    );
    await _reload();
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    ref.invalidate(boardControllerProvider);
    await future;
  }
}

final woDetailControllerProvider =
    AsyncNotifierProvider.autoDispose.family<WoDetailController, WorkOrder,
        String>(
  WoDetailController.new,
);
