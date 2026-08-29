import '../models/part.dart';
import '../models/part_movement.dart';
import 'part_repository.dart';
import 'repository_exception.dart';

class FakePartRepository implements PartRepository {
  FakePartRepository({List<Part>? initial, this.actorName = 'Kasir Satu'}) {
    if (initial != null) _parts.addAll(initial);
  }

  final List<Part> _parts = [];
  final List<PartMovement> _movements = [];
  final String actorName;
  int _seq = 0;

  List<Part> get store => List.unmodifiable(_parts);
  List<PartMovement> get movementStore => List.unmodifiable(_movements);

  double _stockFor(String partId) => _movements
      .where((m) => m.partId == partId)
      .fold(0.0, (sum, m) => sum + m.signedDelta);

  Part _withStock(Part part) => part.copyWith(stockQty: _stockFor(part.id));

  @override
  Future<List<Part>> list({
    String? search,
    bool filterLowStock = false,
    int limit = 50,
    int offset = 0,
  }) async {
    var items = [..._parts];
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      items = items
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.code?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    items.sort((a, b) => a.name.compareTo(b.name));
    final withStock = items.map(_withStock).toList();
    final filtered =
        filterLowStock ? withStock.where((p) => p.isLowStock).toList() : withStock;
    return filtered.skip(offset).take(limit).map((p) => p.copyWith()).toList();
  }

  @override
  Future<Part?> getById(String id) async {
    final found = _parts.where((p) => p.id == id);
    if (found.isEmpty) return null;
    return _withStock(found.first).copyWith();
  }

  @override
  Future<Part> createPart(PartInput input) async {
    final part = Part(
      id: 'p${_parts.length + 1}',
      name: input.name.trim(),
      code: input.code?.trim().isEmpty == true ? null : input.code?.trim(),
      unit: input.unit?.trim().isEmpty == true ? 'pcs' : input.unit?.trim(),
      minStock: input.minStock,
      costPrice: input.costPrice ?? 0,
      sellPrice: input.sellPrice ?? 0,
      stockQty: 0,
      createdAt: DateTime.now(),
    );
    _parts.add(part);
    return _withStock(part).copyWith();
  }

  @override
  Future<Part> updatePart(PartInput input) async {
    if (input.id == null) {
      throw const RepositoryException('ID suku cadang tidak ditemukan');
    }
    final index = _parts.indexWhere((p) => p.id == input.id);
    if (index < 0) throw const RepositoryException('Suku cadang tidak ditemukan');
    final updated = _parts[index].copyWith(
      name: input.name.trim(),
      code: input.code?.trim().isEmpty == true ? null : input.code?.trim(),
      unit: input.unit?.trim().isEmpty == true ? 'pcs' : input.unit?.trim(),
      minStock: input.minStock,
      costPrice: input.costPrice ?? 0,
      sellPrice: input.sellPrice ?? 0,
    );
    _parts[index] = updated;
    return _withStock(updated).copyWith();
  }

  @override
  Future<void> deletePart(String id) async {
    _parts.removeWhere((p) => p.id == id);
    _movements.removeWhere((m) => m.partId == id);
  }

  @override
  Future<void> stockIn(
    String partId,
    double qty, {
    String? note,
    String? distributor,
    double? purchasePrice,
    String paymentType = 'tunai',
    DateTime? dueDate,
    bool updateCostPrice = false,
  }) async {
    if (qty <= 0) {
      throw const RepositoryException('Jumlah stok masuk harus lebih dari 0');
    }
    _appendMovement(
      partId: partId,
      direction: MovementDirection.in_,
      qty: qty,
      refType: MovementRef.pembelian,
      note: note,
      distributor: distributor,
      purchasePrice: purchasePrice,
      paymentType: paymentType,
      debtStatus: paymentType == 'hutang' ? 'belum_lunas' : 'lunas',
      dueDate: dueDate,
    );

    if (updateCostPrice && purchasePrice != null && purchasePrice > 0) {
      final index = _parts.indexWhere((p) => p.id == partId);
      if (index != -1) {
        _parts[index] = _parts[index].copyWith(costPrice: purchasePrice);
      }
    }
  }

  @override
  Future<void> markDebtPaid(String movementId) async {
    final idx = _movements.indexWhere((m) => m.id == movementId);
    if (idx != -1) {
      _movements[idx] = _movements[idx].copyWith(
        debtStatus: 'lunas',
        paidAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<PartMovement>> getOutstandingDebts() async {
    return _movements.where((m) => m.isUnpaidDebt).toList();
  }

  @override
  Future<void> adjustStock(
    String partId,
    double signedDelta,
    String reason,
  ) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw const RepositoryException('Alasan koreksi wajib diisi');
    }
    final resulting = _stockFor(partId) + signedDelta;
    if (resulting < 0) {
      throw const RepositoryException('Stok tidak cukup untuk koreksi ini');
    }
    _appendMovement(
      partId: partId,
      direction: MovementDirection.adjust,
      qty: signedDelta,
      refType: MovementRef.koreksi,
      note: trimmed,
    );
  }

  @override
  Future<List<PartMovement>> movements(String partId) async {
    final items = _movements
        .where((m) => m.partId == partId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.map((m) => m.copyWith()).toList();
  }

  PartMovement _appendMovement({
    required String partId,
    required MovementDirection direction,
    required double qty,
    required MovementRef refType,
    String? note,
    String? distributor,
    double? purchasePrice,
    String paymentType = 'tunai',
    String debtStatus = 'lunas',
    DateTime? dueDate,
  }) {
    final movement = PartMovement(
      id: 'm${_movements.length + 1}',
      partId: partId,
      direction: direction,
      qty: qty,
      refType: refType,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      actorName: actorName,
      distributor: distributor?.trim().isEmpty == true ? null : distributor?.trim(),
      purchasePrice: purchasePrice,
      paymentType: paymentType,
      debtStatus: debtStatus,
      dueDate: dueDate,
      createdAt: DateTime.now().add(Duration(milliseconds: _seq++)),
    );
    _movements.add(movement);
    return movement;
  }
}
