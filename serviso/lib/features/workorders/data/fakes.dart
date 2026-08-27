import 'dart:async';

import '../../auth/models/profile.dart';
import '../../../core/models/wo_status.dart';
import '../data/work_order_repository.dart';
import '../logic/wo_state_machine.dart';
import '../models/payment.dart';
import '../models/work_order.dart';
import 'repository_exception.dart';

class LedgerEntry {
  const LedgerEntry({
    required this.partId,
    required this.direction,
    required this.refType,
    required this.qty,
  });

  final String partId;
  final String direction;
  final String refType;
  final double qty;
}

class FakeWorkOrderRepository implements WorkOrderRepository {
  FakeWorkOrderRepository({this.technicians, Map<String, double>? partStock}) {
    if (partStock != null) _partStock.addAll(partStock);
  }

  final List<WorkOrder> _orders = [];
  final Map<String, double> _partStock = {};
  final List<LedgerEntry> _ledger = [];
  final List<Profile>? technicians;

  List<WorkOrder> get store => List.unmodifiable(_orders);
  List<LedgerEntry> get ledger => List.unmodifiable(_ledger);

  int _seq = 0;

  void seedPartStock(String partId, double qty) => _partStock[partId] = qty;

  final _boardController = StreamController<List<WorkOrder>>.broadcast();

  void _emit() {
    if (!_boardController.isClosed) {
      _boardController.add([..._orders]);
    }
  }

  String _nextWoNumber() {
    final now = DateTime.now();
    final ymd =
        '${now.year % 100}${_pad(now.month)}${_pad(now.day)}';
    _seq++;
    return 'WO-$ymd-${_pad3(_seq)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String _pad3(int n) => n.toString().padLeft(3, '0');

  WorkOrder _byId(String id) {
    final found = _orders.where((o) => o.id == id);
    if (found.isEmpty) throw const RepositoryException('Work order tidak ditemukan');
    return found.first;
  }

  @override
  Stream<List<WorkOrder>> watchBoard() {
    Future(() => _emit());
    return _boardController.stream;
  }

  @override
  Future<WorkOrder?> getById(String id) async {
    final found = _orders.where((o) => o.id == id);
    return found.isEmpty ? null : _withItems(found.first);
  }

  WorkOrder _withItems(WorkOrder order) {
    final items = _itemStore.entries
        .where((e) => e.value.workOrderId == order.id)
        .map((e) => e.value.item)
        .toList();
    return order.copyWith(items: items);
  }

  final Map<String, _ItemEntry> _itemStore = {};

  @override
  Future<WorkOrder> create(WorkOrderDraft draft) async {
    if (draft.complaint == null || draft.complaint!.trim().isEmpty) {
      throw const RepositoryException('Keluhan wajib diisi');
    }
    final id = 'wo${_orders.length + 1}';
    final order = WorkOrder(
      id: id,
      woNumber: _nextWoNumber(),
      status: WoStatus.menunggu,
      vehicleId: draft.vehicleId,
      assignedTo: draft.assignedTo,
      complaint: draft.complaint,
      odometerIn: draft.odometerIn,
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    for (final input in draft.items) {
      _addItemEntry(id, input);
    }
    _emit();
    return _withItems(order);
  }

  void _addItemEntry(String workOrderId, WoItemInput input) {
    final itemId = 'wi${_itemStore.length + 1}';
    final item = WoItem(
      id: itemId,
      kind: input.kind,
      partId: input.partId,
      partName: input.partName,
      description: input.description,
      qty: input.qty,
      unitPrice: input.unitPrice,
      discount: input.discount,
    );
    _itemStore[itemId] = _ItemEntry(workOrderId: workOrderId, item: item);
  }

  @override
  Future<void> start(String id) async {
    final order = _byId(id);
    if (!WoStateMachine.canTransition(order.status, WoEvent.start)) {
      throw const RepositoryException(
        'Work order hanya bisa dimulai dari status Menunggu',
      );
    }
    _update(id, order.copyWith(status: WoStatus.dikerjakan, startedAt: DateTime.now()));
    _emit();
  }

  @override
  Future<void> complete(String id) async {
    final order = _byId(id);
    if (!WoStateMachine.canTransition(order.status, WoEvent.complete)) {
      throw const RepositoryException(
        'Work order hanya bisa diselesaikan dari status Dikerjakan',
      );
    }
    final items = _withItems(order).items;
    final needed = <String, double>{};
    for (final item in items) {
      if (item.kind == WoItemKind.part && item.partId != null) {
        needed[item.partId!] = (needed[item.partId!] ?? 0) + item.qty;
      }
    }
    for (final entry in needed.entries) {
      final available = _partStock[entry.key] ?? 0;
      if (available < entry.value) {
        throw const RepositoryException(
          'Stok tidak cukup untuk menyelesaikan work order',
        );
      }
    }
    for (final entry in needed.entries) {
      _partStock[entry.key] = (_partStock[entry.key] ?? 0) - entry.value;
      _ledger.add(
        LedgerEntry(
          partId: entry.key,
          direction: 'out',
          refType: 'wo',
          qty: entry.value,
        ),
      );
    }
    _update(id, order.copyWith(status: WoStatus.selesai, completedAt: DateTime.now()));
    _emit();
  }

  @override
  Future<void> cancel(String id) async {
    final order = _byId(id);
    if (order.status == WoStatus.dibatalkan) {
      throw const RepositoryException('Work order sudah dibatalkan');
    }
    if (!WoStateMachine.canTransition(order.status, WoEvent.cancel)) {
      throw const RepositoryException('Transisi status tidak diizinkan');
    }
    if (order.status == WoStatus.selesai) {
      final items = _withItems(order).items;
      final returned = <String, double>{};
      for (final item in items) {
        if (item.kind == WoItemKind.part && item.partId != null) {
          returned[item.partId!] = (returned[item.partId!] ?? 0) + item.qty;
        }
      }
      for (final entry in returned.entries) {
        _partStock[entry.key] = (_partStock[entry.key] ?? 0) + entry.value;
        _ledger.add(
          LedgerEntry(
            partId: entry.key,
            direction: 'in',
            refType: 'pembatalan',
            qty: entry.value,
          ),
        );
      }
    }
    _update(id, order.copyWith(status: WoStatus.dibatalkan));
    _emit();
  }

  @override
  Future<void> pay({
    required String id,
    required double paidAmount,
    required PaymentMethod payMethod,
  }) async {
    final order = _byId(id);
    _update(
      id,
      order.copyWith(
        paidAmount: paidAmount,
        payMethod: payMethod,
        paidAt: DateTime.now(),
      ),
    );
    _emit();
  }

  @override
  Future<void> addItem(String id, WoItemInput item) async {
    final order = _byId(id);
    if (order.status != WoStatus.menunggu &&
        order.status != WoStatus.dikerjakan) {
      throw const RepositoryException(
        'Item hanya bisa ditambah saat work order Menunggu atau Dikerjakan',
      );
    }
    if (item.qty <= 0) {
      throw const RepositoryException('Jumlah item harus lebih dari 0');
    }
    _addItemEntry(id, item);
    _emit();
  }

  @override
  Future<void> removeItem(String id, String itemId) async {
    final order = _byId(id);
    if (order.status != WoStatus.menunggu &&
        order.status != WoStatus.dikerjakan) {
      throw const RepositoryException(
        'Item hanya bisa dihapus saat work order Menunggu atau Dikerjakan',
      );
    }
    _itemStore.remove(itemId);
    _emit();
  }

  @override
  Future<void> updateDetail({
    required String id,
    String? complaint,
    String? diagnosis,
    String? techNote,
  }) async {
    final order = _byId(id);
    _update(
      id,
      order.copyWith(
        complaint: complaint ?? order.complaint,
        diagnosis: diagnosis ?? order.diagnosis,
        techNote: techNote ?? order.techNote,
      ),
    );
    _emit();
  }

  @override
  Future<List<Profile>> listTechnicians() async {
    return technicians ??
        const [
          Profile(
            id: 't1',
            username: 'mekanik1',
            fullName: 'Budi Mekanik',
            role: UserRole.mekanik,
            isActive: true,
          ),
          Profile(
            id: 't2',
            username: 'mekanik2',
            fullName: 'Sari Mekanik',
            role: UserRole.mekanik,
            isActive: true,
          ),
        ];
  }

  void _update(String id, WorkOrder updated) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index >= 0) _orders[index] = updated;
  }
}

class _ItemEntry {
  const _ItemEntry({required this.workOrderId, required this.item});

  final String workOrderId;
  final WoItem item;
}
