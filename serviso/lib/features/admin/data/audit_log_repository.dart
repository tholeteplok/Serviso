import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/inventori/data/repository_exception.dart';
import '../models/admin_models.dart';

abstract class AuditLogRepository {
  Future<List<AuditLogEntry>> fetchAuditLogs({
    AuditLogFilter? filter,
    int limit = 25,
    int offset = 0,
  });
}

class SupabaseAuditLogRepository implements AuditLogRepository {
  SupabaseAuditLogRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AuditLogEntry>> fetchAuditLogs({
    AuditLogFilter? filter,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('audit_logs')
          .select('*, profiles:actor_id(full_name)');

      if (filter != null) {
        if (filter.tableName != null && filter.tableName!.isNotEmpty) {
          query = query.eq('table_name', filter.tableName!);
        }
        if (filter.action != null && filter.action!.isNotEmpty) {
          query = query.eq('action', filter.action!);
        }
        if (filter.actorId != null && filter.actorId!.isNotEmpty) {
          query = query.eq('actor_id', filter.actorId!);
        }
        if (filter.startDate != null) {
          query = query.gte('created_at', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('created_at', filter.endDate!.toIso8601String());
        }
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List).map((m) => AuditLogEntry.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }
}

class FakeAuditLogRepository implements AuditLogRepository {
  List<AuditLogEntry> mockLogs = [
    AuditLogEntry(
      id: 101,
      actorId: 'u1',
      actorName: 'Pemilik Bengkel',
      action: 'update',
      tableName: 'parts',
      recordId: 'p1',
      oldData: {'name': 'Oli Mesin 1L', 'sell_price': 90000},
      newData: {'name': 'Oli Mesin 1L', 'sell_price': 100000},
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AuditLogEntry(
      id: 100,
      actorId: 'u2',
      actorName: 'Budi Kasir',
      action: 'insert',
      tableName: 'work_orders',
      recordId: 'wo-1',
      oldData: null,
      newData: {'wo_number': 'WO-260828-001', 'status': 'menunggu'},
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AuditLogEntry(
      id: 99,
      actorId: 'u2',
      actorName: 'Budi Kasir',
      action: 'login',
      tableName: 'auth',
      recordId: 'u2',
      oldData: null,
      newData: null,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<AuditLogEntry>> fetchAuditLogs({
    AuditLogFilter? filter,
    int limit = 25,
    int offset = 0,
  }) async {
    var filtered = List<AuditLogEntry>.from(mockLogs);
    if (filter != null) {
      if (filter.tableName != null && filter.tableName!.isNotEmpty) {
        filtered = filtered.where((l) => l.tableName == filter.tableName).toList();
      }
      if (filter.action != null && filter.action!.isNotEmpty) {
        filtered = filtered.where((l) => l.action == filter.action).toList();
      }
    }
    final end = (offset + limit) > filtered.length ? filtered.length : (offset + limit);
    if (offset >= filtered.length) return [];
    return filtered.sublist(offset, end);
  }
}
