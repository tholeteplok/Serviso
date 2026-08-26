import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/part.dart';
import '../models/part_movement.dart';
import 'repository_exception.dart';

abstract class PartRepository {
  Future<List<Part>> list({
    String? search,
    bool filterLowStock = false,
    int limit = 50,
    int offset = 0,
  });

  Future<Part?> getById(String id);

  Future<Part> createPart(PartInput input);

  Future<Part> updatePart(PartInput input);

  Future<void> deletePart(String id);

  Future<void> stockIn(String partId, double qty, {String? note});

  Future<void> adjustStock(String partId, double signedDelta, String reason);

  Future<List<PartMovement>> movements(String partId);
}

class SupabasePartRepository implements PartRepository {
  SupabasePartRepository(this._client);

  final SupabaseClient _client;

  String _sanitize(String query) =>
      query.trim().replaceAll(RegExp(r'[%/_]'), '');

  @override
  Future<List<Part>> list({
    String? search,
    bool filterLowStock = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('parts').select().order('name');
      final q = search?.trim();
      if (q != null && q.isNotEmpty) {
        final safe = _sanitize(q);
        query = _client
            .from('parts')
            .select()
            .or('name.ilike.%$safe%,code.ilike.%$safe%')
            .order('name');
      }
      final result = await query.range(offset, offset + limit - 1);
      final parts =
          (result as List).map((m) => Part.fromMap(m)).toList();
      if (!filterLowStock) return parts;
      return parts.where((p) => p.isLowStock).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Part?> getById(String id) async {
    try {
      final data = await _client
          .from('parts')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Part.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Part> createPart(PartInput input) async {
    try {
      final data = await _client
          .from('parts')
          .insert(input.toMap())
          .select()
          .single();
      return Part.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<Part> updatePart(PartInput input) async {
    if (input.id == null) {
      throw const RepositoryException('ID suku cadang tidak ditemukan');
    }
    try {
      final data = await _client
          .from('parts')
          .update(input.toMap())
          .eq('id', input.id!)
          .select()
          .single();
      return Part.fromMap(data);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> deletePart(String id) async {
    try {
      await _client.from('parts').delete().eq('id', id);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> stockIn(String partId, double qty, {String? note}) async {
    try {
      await _client.from('part_movements').insert({
        'part_id': partId,
        'direction': 'in',
        'qty': qty,
        'ref_type': 'pembelian',
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
      });
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
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
    try {
      await _client.from('part_movements').insert({
        'part_id': partId,
        'direction': 'adjust',
        'qty': signedDelta,
        'ref_type': 'koreksi',
        'note': trimmed,
      });
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<PartMovement>> movements(String partId) async {
    try {
      final result = await _client
          .from('part_movements')
          .select('*, profiles:created_by(full_name)')
          .eq('part_id', partId)
          .order('created_at', ascending: false);
      return (result as List)
          .map((m) => PartMovement.fromMap(m))
          .toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }
}
