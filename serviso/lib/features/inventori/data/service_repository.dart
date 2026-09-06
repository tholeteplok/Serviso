import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_item.dart';
import 'repository_exception.dart';

abstract class ServiceRepository {
  Future<List<ServiceItem>> list({
    String? search,
    int limit = 50,
    int offset = 0,
  });

  Future<ServiceItem?> getById(String id);

  Future<ServiceItem> create(ServiceInput input);

  Future<ServiceItem> update(String id, ServiceInput input);

  Future<void> delete(String id);
}

class SupabaseServiceRepository implements ServiceRepository {
  SupabaseServiceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ServiceItem>> list({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('services').select();

      final s = search?.trim();
      if (s != null && s.isNotEmpty) {
        query = query.or('name.ilike.%$s%,code.ilike.%$s%');
      }

      final data = await query
          .eq('is_active', true)
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);

      return (data as List)
          .map((m) => ServiceItem.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<ServiceItem?> getById(String id) async {
    try {
      final data = await _client
          .from('services')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return ServiceItem.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<ServiceItem> create(ServiceInput input) async {
    try {
      final data = await _client
          .from('services')
          .insert(input.toMap())
          .select()
          .single();

      return ServiceItem.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<ServiceItem> update(String id, ServiceInput input) async {
    try {
      final data = await _client
          .from('services')
          .update(input.toMap())
          .eq('id', id)
          .select()
          .single();

      return ServiceItem.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from('services').delete().eq('id', id);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }
}

class FakeServiceRepository implements ServiceRepository {
  final List<ServiceItem> _services = [];

  @override
  Future<List<ServiceItem>> list({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    var items = List<ServiceItem>.from(_services);
    items = items.where((s) => s.isActive).toList();

    final s = search?.trim().toLowerCase();
    if (s != null && s.isNotEmpty) {
      items = items.where((item) {
        final matchName = item.name.toLowerCase().contains(s);
        final matchCode = item.code?.toLowerCase().contains(s) ?? false;
        return matchName || matchCode;
      }).toList();
    }

    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (offset >= items.length) return [];
    final end = (offset + limit < items.length) ? offset + limit : items.length;
    return items.sublist(offset, end);
  }

  @override
  Future<ServiceItem?> getById(String id) async {
    final match = _services.where((s) => s.id == id);
    return match.isEmpty ? null : match.first;
  }

  @override
  Future<ServiceItem> create(ServiceInput input) async {
    final newItem = ServiceItem(
      id: 'srv-${DateTime.now().millisecondsSinceEpoch}-${_services.length}',
      name: input.name.trim(),
      code: input.code?.trim().isEmpty == true ? null : input.code?.trim(),
      description: input.description?.trim().isEmpty == true ? null : input.description?.trim(),
      price: input.price,
      isActive: input.isActive,
      createdAt: DateTime.now(),
    );
    _services.add(newItem);
    return newItem;
  }

  @override
  Future<ServiceItem> update(String id, ServiceInput input) async {
    final idx = _services.indexWhere((s) => s.id == id);
    if (idx == -1) throw const RepositoryException('Layanan jasa tidak ditemukan');

    final updated = _services[idx].copyWith(
      name: input.name.trim(),
      code: input.code?.trim().isEmpty == true ? null : input.code?.trim(),
      description: input.description?.trim().isEmpty == true ? null : input.description?.trim(),
      price: input.price,
      isActive: input.isActive,
    );
    _services[idx] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _services.removeWhere((s) => s.id == id);
  }
}
