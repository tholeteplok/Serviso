import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';
import 'repository_exception.dart';

abstract class CustomerRepository {
  Future<List<Customer>> list({int limit = 50, int offset = 0});

  Future<List<Customer>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  });

  Future<Customer> create(CustomerInput input);

  Future<Customer> update(CustomerInput input);

  Future<void> delete(String id);

  Future<Customer?> getById(String id);

  Future<int> workOrderCount(String customerId);
}

class SupabaseCustomerRepository implements CustomerRepository {
  SupabaseCustomerRepository(this._client);

  final SupabaseClient _client;

  static const _columns = '*, vehicles(count)';

  @override
  Future<List<Customer>> list({int limit = 50, int offset = 0}) async {
    try {
      final result = await _client
          .from('customers')
          .select(_columns)
          .order('name')
          .range(offset, offset + limit - 1);
      return (result as List).map((m) => Customer.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<Customer>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final q = _sanitize(query);
    try {
      final result = await _client
          .from('customers')
          .select(_columns)
          .or('name.ilike.%$q%,phone.ilike.%$q%')
          .order('name')
          .range(offset, offset + limit - 1);
      return (result as List).map((m) => Customer.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Customer> create(CustomerInput input) async {
    try {
      final data = await _client
          .from('customers')
          .insert(input.toMap())
          .select(_columns)
          .single();
      return Customer.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Customer> update(CustomerInput input) async {
    if (input.id == null) {
      throw const RepositoryException('ID pelanggan tidak ditemukan');
    }
    try {
      final data = await _client
          .from('customers')
          .update(input.toMap())
          .eq('id', input.id!)
          .select(_columns)
          .single();
      return Customer.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Customer?> getById(String id) async {
    try {
      final data = await _client
          .from('customers')
          .select(_columns)
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Customer.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<int> workOrderCount(String customerId) async {
    try {
      final result = await _client
          .from('work_orders')
          .select('id, vehicles!inner(customer_id)')
          .eq('vehicles.customer_id', customerId);
      return (result as List).length;
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  String _sanitize(String query) =>
      query.trim().replaceAll(RegExp(r'[%/_]'), '');
}
