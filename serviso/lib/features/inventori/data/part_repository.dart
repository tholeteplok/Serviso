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

  Future<void> stockIn(
    String partId,
    double qty, {
    String? note,
    String? distributor,
    double? purchasePrice,
    String paymentType = 'tunai',
    DateTime? dueDate,
    bool updateCostPrice = false,
  });

  Future<void> markDebtPaid(String movementId);

  Future<List<PartMovement>> getOutstandingDebts();

  Future<void> adjustStock(String partId, double signedDelta, String reason);

  Future<List<PartMovement>> movements(String partId);

  Future<List<String>> fetchDistributors();
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
      if (filterLowStock) {
        final q = search?.trim();
        // Jika filter low-stock tanpa search, pakai view akurat
        if (q == null || q.isEmpty) {
          try {
            final res = await _client
                .from('v_low_stock_parts')
                .select()
                .range(offset, offset + limit - 1);
            return (res as List).map((m) => Part.fromMap(m)).toList();
          } catch (_) {
            // fallback ke parts
          }
        }
        // Dengan search + low-stock: ambil lebih banyak + filter server
        final effectiveLimit = 200;
        var query = _client.from('parts').select().order('name');
        if (q != null && q.isNotEmpty) {
          final safe = _sanitize(q);
          query = _client
              .from('parts')
              .select()
              .or('name.ilike.%$safe%,code.ilike.%$safe%')
              .gt('min_stock', 0)
              .order('name');
        } else {
          query = _client.from('parts').select().gt('min_stock', 0).order('name');
        }
        final result = await query.range(0, effectiveLimit - 1);
        final parts = (result as List).map((m) => Part.fromMap(m)).toList();
        return parts.where((p) => p.isLowStock).toList();
      }
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
      return (result as List).map((m) => Part.fromMap(m)).toList();
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
      final part = Part.fromMap(data);
      if (input.initialStock > 0) {
        await stockIn(
          part.id,
          input.initialStock,
          note: 'Stok awal',
          distributor: input.distributor,
          purchasePrice: input.costPrice,
          paymentType: input.paymentType,
          dueDate: input.dueDate,
          updateCostPrice: false,
        );
        final refreshed = await getById(part.id);
        return refreshed ?? part;
      }
      return part;
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
    try {
      final insertMap = <String, dynamic>{
        'part_id': partId,
        'direction': 'in',
        'qty': qty,
        'ref_type': 'pembelian',
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
        'distributor': distributor?.trim().isEmpty == true ? null : distributor?.trim(),
        'purchase_price': purchasePrice,
        'payment_type': paymentType,
        'debt_status': paymentType == 'hutang' ? 'belum_lunas' : 'lunas',
        'due_date': dueDate?.toIso8601String().substring(0, 10),
      };

      try {
        await _client.from('part_movements').insert(insertMap);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isMissingColumn = msg.contains('column') && msg.contains('does not exist') ||
            msg.contains('schema cache') ||
            msg.contains('could not find');
        if (!isMissingColumn) rethrow;
        // Graceful fallback if new columns not yet migrated
        var fallbackNote = note?.trim() ?? '';
        if (distributor?.trim().isNotEmpty == true) {
          fallbackNote = '[Distributor: ${distributor!.trim()}] $fallbackNote'.trim();
        }
        if (paymentType == 'hutang') {
          fallbackNote = '[HUTANG] $fallbackNote'.trim();
        }
        await _client.from('part_movements').insert({
          'part_id': partId,
          'direction': 'in',
          'qty': qty,
          'ref_type': 'pembelian',
          'note': fallbackNote.isEmpty ? null : fallbackNote,
        });
      }

      if (updateCostPrice && purchasePrice != null && purchasePrice > 0) {
        await _client.from('parts').update({'cost_price': purchasePrice}).eq('id', partId);
      }
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> markDebtPaid(String movementId) async {
    try {
      await _client
          .from('part_movements')
          .update({
            'debt_status': 'lunas',
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', movementId);
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<PartMovement>> getOutstandingDebts() async {
    try {
      final res = await _client
          .from('part_movements')
          .select('*, profiles:created_by(full_name)')
          .eq('payment_type', 'hutang')
          .eq('debt_status', 'belum_lunas')
          .order('created_at', ascending: false);
      return (res as List).map((m) => PartMovement.fromMap(m)).toList();
    } catch (_) {
      return [];
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

  @override
  Future<List<String>> fetchDistributors() async {
    try {
      final result = await _client
          .from('part_movements')
          .select('distributor, note')
          .or('distributor.not.is.null,note.ilike.%[Distributor:%');
      final set = <String>{};
      for (final row in result as List) {
        final dist = row['distributor'] as String?;
        if (dist != null && dist.trim().isNotEmpty) {
          set.add(dist.trim());
        }
        final note = row['note'] as String?;
        if (note != null && note.contains('[Distributor:')) {
          final match =
              RegExp(r'\[Distributor:\s*([^\]]+)\]').firstMatch(note);
          if (match != null) {
            final extracted = match.group(1)?.trim();
            if (extracted != null && extracted.isNotEmpty) {
              set.add(extracted);
            }
          }
        }
      }
      final list = set.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return list;
    } catch (_) {
      return [];
    }
  }
}
