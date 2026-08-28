import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import 'repository_exception.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> listByCustomer(
    String customerId, {
    int limit = 50,
    int offset = 0,
  });

  Future<List<Vehicle>> searchVehicles(
    String query, {
    int limit = 50,
    int offset = 0,
  });

  Future<Vehicle> create(VehicleInput input);

  Future<Vehicle> update(VehicleInput input);

  Future<void> delete(String id);

  Future<Vehicle?> getById(String id);
}

class SupabaseVehicleRepository implements VehicleRepository {
  SupabaseVehicleRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Vehicle>> listByCustomer(
    String customerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _client
          .from('vehicles')
          .select()
          .eq('customer_id', customerId)
          .order('plate_no')
          .range(offset, offset + limit - 1);
      return (result as List).map((m) => Vehicle.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<Vehicle>> searchVehicles(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final q = _sanitize(query);
    if (q.isEmpty) return [];
    try {
      final matchingCustomers = await _client
          .from('customers')
          .select('id')
          .ilike('name', '%$q%');
      final customerIds = (matchingCustomers as List)
          .map((c) => c['id'] as String)
          .toList();

      var filter = 'plate_no.ilike.%$q%,brand.ilike.%$q%,model.ilike.%$q%';
      if (customerIds.isNotEmpty) {
        filter += ',customer_id.in.(${customerIds.join(',')})';
      }

      final result = await _client
          .from('vehicles')
          .select('*, customers(name)')
          .or(filter)
          .order('plate_no')
          .range(offset, offset + limit - 1);
      return (result as List).map((m) => Vehicle.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Vehicle> create(VehicleInput input) async {
    try {
      final data = await _client
          .from('vehicles')
          .insert(input.toMap())
          .select()
          .single();
      return Vehicle.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Vehicle> update(VehicleInput input) async {
    if (input.id == null) {
      throw const RepositoryException('ID kendaraan tidak ditemukan');
    }
    try {
      final data = await _client
          .from('vehicles')
          .update(input.toMap(includeCustomerId: false))
          .eq('id', input.id!)
          .select()
          .single();
      return Vehicle.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from('vehicles').delete().eq('id', id);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Vehicle?> getById(String id) async {
    try {
      final data = await _client
          .from('vehicles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Vehicle.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  String _sanitize(String query) =>
      query.trim().replaceAll(RegExp(r'[%/_]'), '');
}
