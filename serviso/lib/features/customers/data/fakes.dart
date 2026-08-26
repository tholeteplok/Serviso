import '../models/customer.dart';
import '../models/vehicle.dart';
import 'customer_repository.dart';
import 'repository_exception.dart';
import 'vehicle_repository.dart';

class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository({
    List<Customer>? initial,
    this.workOrderCounts,
    this.throwRestrictOnDelete = false,
  }) {
    if (initial != null) _store.addAll(initial);
  }

  final List<Customer> _store = [];
  final Map<String, int>? workOrderCounts;
  final bool throwRestrictOnDelete;

  List<Customer> get store => List.unmodifiable(_store);

  @override
  Future<List<Customer>> list({int limit = 50, int offset = 0}) async {
    final sorted = [..._store]..sort((a, b) => a.name.compareTo(b.name));
    return sorted.skip(offset).take(limit).map(_copy).toList();
  }

  @override
  Future<List<Customer>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final q = query.toLowerCase();
    final filtered = _store.where((c) {
      final name = c.name.toLowerCase();
      final phone = (c.phone ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return filtered.skip(offset).take(limit).map(_copy).toList();
  }

  @override
  Future<Customer> create(CustomerInput input) async {
    final customer = Customer(
      id: 'c${_store.length + 1}',
      name: input.name.trim(),
      phone: input.phone?.trim().isEmpty == true ? null : input.phone?.trim(),
      address:
          input.address?.trim().isEmpty == true ? null : input.address?.trim(),
      note: input.note?.trim().isEmpty == true ? null : input.note?.trim(),
      createdAt: DateTime.now(),
    );
    _store.add(customer);
    return _copy(customer);
  }

  @override
  Future<Customer> update(CustomerInput input) async {
    final index = _store.indexWhere((c) => c.id == input.id);
    if (index < 0) throw const RepositoryException('Pelanggan tidak ditemukan');
    final updated = _store[index].copyWith(
      name: input.name.trim(),
      phone: input.phone?.trim().isEmpty == true ? null : input.phone?.trim(),
      address:
          input.address?.trim().isEmpty == true ? null : input.address?.trim(),
      note: input.note?.trim().isEmpty == true ? null : input.note?.trim(),
    );
    _store[index] = updated;
    return _copy(updated);
  }

  @override
  Future<void> delete(String id) async {
    if (throwRestrictOnDelete) {
      throw const RepositoryException('Hapus dulu kendaraan milik pelanggan ini');
    }
    _store.removeWhere((c) => c.id == id);
  }

  @override
  Future<Customer?> getById(String id) async {
    final found = _store.where((c) => c.id == id);
    return found.isEmpty ? null : _copy(found.first);
  }

  @override
  Future<int> workOrderCount(String customerId) async {
    return workOrderCounts?[customerId] ?? 0;
  }

  Customer _copy(Customer c) => c.copyWith();
}

class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository({
    List<Vehicle>? initial,
    this.throwDuplicatePlate = false,
  }) {
    if (initial != null) _store.addAll(initial);
  }

  final List<Vehicle> _store = [];
  final bool throwDuplicatePlate;

  List<Vehicle> get store => List.unmodifiable(_store);

  @override
  Future<List<Vehicle>> listByCustomer(
    String customerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final filtered = _store
        .where((v) => v.customerId == customerId)
        .toList()
      ..sort((a, b) => a.plateNo.compareTo(b.plateNo));
    return filtered.skip(offset).take(limit).map(_copy).toList();
  }

  @override
  Future<List<Vehicle>> searchVehicles(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final q = query.toLowerCase();
    final filtered = _store
        .where((v) => v.plateNo.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.plateNo.compareTo(b.plateNo));
    return filtered.skip(offset).take(limit).map(_copy).toList();
  }

  @override
  Future<Vehicle> create(VehicleInput input) async {
    if (throwDuplicatePlate) {
      throw const RepositoryException('Plat nomor sudah terdaftar');
    }
    final vehicle = Vehicle(
      id: 'v${_store.length + 1}',
      customerId: input.customerId,
      plateNo: input.plateNo.trim().toUpperCase(),
      brand: input.brand?.trim().isEmpty == true ? null : input.brand?.trim(),
      model: input.model?.trim().isEmpty == true ? null : input.model?.trim(),
      year: input.year,
      color: input.color?.trim().isEmpty == true ? null : input.color?.trim(),
      createdAt: DateTime.now(),
    );
    _store.add(vehicle);
    return _copy(vehicle);
  }

  @override
  Future<Vehicle> update(VehicleInput input) async {
    final index = _store.indexWhere((v) => v.id == input.id);
    if (index < 0) throw const RepositoryException('Kendaraan tidak ditemukan');
    if (throwDuplicatePlate) {
      throw const RepositoryException('Plat nomor sudah terdaftar');
    }
    final updated = _store[index].copyWith(
      plateNo: input.plateNo.trim().toUpperCase(),
      brand: input.brand?.trim().isEmpty == true ? null : input.brand?.trim(),
      model: input.model?.trim().isEmpty == true ? null : input.model?.trim(),
      year: input.year,
      color: input.color?.trim().isEmpty == true ? null : input.color?.trim(),
    );
    _store[index] = updated;
    return _copy(updated);
  }

  @override
  Future<void> delete(String id) async {
    _store.removeWhere((v) => v.id == id);
  }

  @override
  Future<Vehicle?> getById(String id) async {
    final found = _store.where((v) => v.id == id);
    return found.isEmpty ? null : _copy(found.first);
  }

  Vehicle _copy(Vehicle v) => v.copyWith();
}
