import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/inventori/data/repository_exception.dart';
import '../models/report_models.dart';

abstract class ReportRepository {
  Future<DashboardSummary> fetchDashboardSummary();

  Future<List<DailySummaryRow>> fetchDailySummaries({
    required DateTime start,
    required DateTime end,
  });

  Future<List<TopPartRow>> fetchTopParts({required DateTime month});

  Future<QueueCounts> fetchQueueCounts();

  Future<OwnerFinancialSummary> fetchOwnerFinancialSummary({
    required DateTime start,
    required DateTime end,
  });

  Future<List<DistributorDebtItem>> fetchDistributorDebts({String? status});

  Future<void> markDebtPaid(String movementId);

  Future<List<ProfitBreakdownRow>> fetchProfitBreakdown({
    required DateTime start,
    required DateTime end,
  });

  Future<List<WoDoneRow>> fetchCompletedWorkOrders({
    required DateTime start,
    required DateTime end,
  });

  Future<List<PartSoldDetailRow>> fetchPartsSoldDetail({
    required DateTime start,
    required DateTime end,
  });

  Future<List<HppRow>> fetchHppDetail({
    required DateTime start,
    required DateTime end,
  });
}

class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<DashboardSummary> fetchDashboardSummary() async {
    try {
      final now = DateTime.now();
      final todayStr = now.toIso8601String().substring(0, 10);
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final sevenDaysAgoStr = sevenDaysAgo.toIso8601String().substring(0, 10);

      // Fetch 7 days summary
      final dailyResult = await _client
          .from('v_daily_summary')
          .select()
          .gte('date', sevenDaysAgoStr)
          .lte('date', todayStr)
          .order('date', ascending: true);
      final dailyRows =
          (dailyResult as List).map((m) => DailySummaryRow.fromMap(m)).toList();

      final todayRow = dailyRows.firstWhere(
        (r) => r.date.toIso8601String().substring(0, 10) == todayStr,
        orElse: () => DailySummaryRow(
          date: now,
          revenue: 0,
          woDoneCount: 0,
          partsOutQty: 0,
        ),
      );

      // Fetch active WOs (menunggu or dikerjakan)
      final activeWoResult = await _client
          .from('work_orders')
          .select('id')
          .inFilter('status', ['menunggu', 'dikerjakan']);
      final activeWoCount = (activeWoResult as List).length;

      // Fetch low stock parts count
      final partsResult = await _client.from('parts').select('stock_qty, min_stock');
      final lowStockCount = (partsResult as List).where((p) {
        final stock = (p['stock_qty'] as num?)?.toDouble() ?? 0;
        final minStock = (p['min_stock'] as num?)?.toInt() ?? 0;
        return minStock > 0 && stock <= minStock;
      }).length;

      return DashboardSummary(
        todayRevenue: todayRow.revenue,
        activeWoCount: activeWoCount,
        lowStockCount: lowStockCount,
        last7Days: dailyRows,
      );
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<DailySummaryRow>> fetchDailySummaries({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      final result = await _client
          .from('v_daily_summary')
          .select()
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: true);

      return (result as List).map((m) => DailySummaryRow.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<TopPartRow>> fetchTopParts({required DateTime month}) async {
    try {
      final monthStart = DateTime(month.year, month.month, 1)
          .toIso8601String()
          .substring(0, 10);

      final result = await _client
          .from('v_top_parts')
          .select()
          .eq('month_start', monthStart)
          .order('qty_out', ascending: false)
          .limit(10);

      return (result as List).map((m) => TopPartRow.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<QueueCounts> fetchQueueCounts() async {
    try {
      final result = await _client.from('work_orders').select('status');
      final list = result as List;
      int waiting = 0;
      int inProgress = 0;
      int done = 0;
      for (final item in list) {
        final status = item['status'] as String?;
        if (status == 'menunggu') waiting++;
        if (status == 'dikerjakan') inProgress++;
        if (status == 'selesai') done++;
      }
      return QueueCounts(
        waiting: waiting,
        inProgress: inProgress,
        done: done,
      );
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<OwnerFinancialSummary> fetchOwnerFinancialSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      // 1. Total revenue in range from v_daily_summary
      final dailyRes = await _client
          .from('v_daily_summary')
          .select('revenue')
          .gte('date', startStr)
          .lte('date', endStr);
      double totalRev = 0.0;
      for (final r in dailyRes as List) {
        totalRev += (r['revenue'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Total COGS (modal part) from wo_items join parts
      double totalCogs = 0.0;
      try {
        final cogsRes = await _client
            .from('wo_items')
            .select('qty, parts(cost_price), work_orders!inner(status, completed_at)')
            .eq('kind', 'part')
            .eq('work_orders.status', 'selesai')
            .gte('work_orders.completed_at', '${startStr}T00:00:00')
            .lte('work_orders.completed_at', '${endStr}T23:59:59');
        for (final item in cogsRes as List) {
          final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
          final partMap = item['parts'] as Map?;
          final cost = (partMap?['cost_price'] as num?)?.toDouble() ?? 0.0;
          totalCogs += qty * cost;
        }
      } catch (_) {
        // Safe fallback
      }

      // 3. Total unpaid debts
      double totalUnpaid = 0.0;
      try {
        final debtsRes = await _client
            .from('part_movements')
            .select('qty, purchase_price, payment_type, debt_status, note, parts(cost_price)')
            .or('payment_type.eq.hutang,note.ilike.%[HUTANG]%');
        for (final d in debtsRes as List) {
          final note = (d['note'] as String?) ?? '';
          final payType = (d['payment_type'] as String?) ??
              (note.contains('[HUTANG]') ? 'hutang' : 'tunai');
          final dStatus = (d['debt_status'] as String?) ??
              (note.contains('[LUNAS]') ? 'lunas' : 'belum_lunas');
          if (payType == 'hutang' && dStatus == 'belum_lunas') {
            final q = (d['qty'] as num?)?.toDouble() ?? 0.0;
            final partMap = d['parts'] as Map?;
            final costFallback =
                (partMap?['cost_price'] as num?)?.toDouble() ?? 0.0;
            final p = (d['purchase_price'] as num?)?.toDouble() ?? costFallback;
            totalUnpaid += q * p;
          }
        }
      } catch (_) {
        // Fallback if columns don't exist yet on Supabase
        try {
          final fallbackRes = await _client
              .from('part_movements')
              .select('qty, note, parts(cost_price)')
              .ilike('note', '%[HUTANG]%');
          for (final d in fallbackRes as List) {
            final note = (d['note'] as String?) ?? '';
            if (note.contains('[HUTANG]') && !note.contains('[LUNAS]')) {
              final q = (d['qty'] as num?)?.toDouble() ?? 0.0;
              final partMap = d['parts'] as Map?;
              final cost = (partMap?['cost_price'] as num?)?.toDouble() ?? 0.0;
              totalUnpaid += q * cost;
            }
          }
        } catch (_) {}
      }

      return OwnerFinancialSummary(
        totalRevenue: totalRev,
        totalCogs: totalCogs,
        totalUnpaidDebt: totalUnpaid,
      );
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<DistributorDebtItem>> fetchDistributorDebts({String? status}) async {
    try {
      final res = await _client
          .from('part_movements')
          .select('id, part_id, qty, purchase_price, distributor, created_at, due_date, debt_status, note, parts(name, cost_price)')
          .or('payment_type.eq.hutang,note.ilike.%[HUTANG]%')
          .order('created_at', ascending: false);

      final list = <DistributorDebtItem>[];
      for (final m in res as List) {
        final note = (m['note'] as String?) ?? '';
        final payType = (m['payment_type'] as String?) ??
            (note.contains('[HUTANG]') ? 'hutang' : 'tunai');
        final dStatus = (m['debt_status'] as String?) ??
            (note.contains('[LUNAS]') ? 'lunas' : 'belum_lunas');

        if (status != null && dStatus != status) continue;
        final isUnpaid = payType == 'hutang' && dStatus == 'belum_lunas';
        final shouldInclude = status != null ? payType == 'hutang' : isUnpaid;
        if (shouldInclude) {
          final partMap = m['parts'] as Map?;
          final pName = (partMap?['name'] as String?) ?? 'Suku Cadang';
          final costFallback =
              (partMap?['cost_price'] as num?)?.toDouble() ?? 0.0;
          final qty = (m['qty'] as num?)?.toDouble() ?? 0.0;
          final price =
              (m['purchase_price'] as num?)?.toDouble() ?? costFallback;

          var dist = m['distributor'] as String?;
          if ((dist == null || dist.isEmpty) && note.contains('[Distributor:')) {
            final match =
                RegExp(r'\[Distributor:\s*([^\]]+)\]').firstMatch(note);
            if (match != null) dist = match.group(1)?.trim();
          }

          list.add(DistributorDebtItem(
            movementId: m['id'] as String,
            partId: m['part_id'] as String,
            partName: pName,
            distributor: (dist != null && dist.isNotEmpty)
                ? dist
                : 'Distributor Umum',
            qty: qty,
            purchasePrice: price,
            totalDebt: qty * price,
            createdAt: DateTime.parse(m['created_at'].toString()),
            dueDate: m['due_date'] != null
                ? DateTime.tryParse(m['due_date'].toString())
                : null,
            debtStatus: dStatus,
          ));
        }
      }
      return list;
    } catch (_) {
      // Fallback query if columns don't exist yet on Supabase:
      try {
        final fallbackRes = await _client
            .from('part_movements')
            .select('id, part_id, qty, created_at, note, parts(name, cost_price)')
            .ilike('note', '%[HUTANG]%')
            .order('created_at', ascending: false);

        final list = <DistributorDebtItem>[];
        for (final m in fallbackRes as List) {
          final note = (m['note'] as String?) ?? '';
          final matchesStatus = status == null
              ? (note.contains('[HUTANG]') && !note.contains('[LUNAS]'))
              : (status == 'lunas'
                  ? note.contains('[LUNAS]')
                  : note.contains('[HUTANG]') && !note.contains('[LUNAS]'));
          if (matchesStatus) {
            final partMap = m['parts'] as Map?;
            final pName = (partMap?['name'] as String?) ?? 'Suku Cadang';
            final cost = (partMap?['cost_price'] as num?)?.toDouble() ?? 0.0;
            final qty = (m['qty'] as num?)?.toDouble() ?? 0.0;

            String dist = 'Distributor Umum';
            if (note.contains('[Distributor:')) {
              final match =
                  RegExp(r'\[Distributor:\s*([^\]]+)\]').firstMatch(note);
              if (match != null) dist = match.group(1)?.trim() ?? dist;
            }

            list.add(DistributorDebtItem(
              movementId: m['id'] as String,
              partId: m['part_id'] as String,
              partName: pName,
              distributor: dist,
              qty: qty,
              purchasePrice: cost,
              totalDebt: qty * cost,
              createdAt: DateTime.parse(m['created_at'].toString()),
              dueDate: null,
              debtStatus: note.contains('[LUNAS]') ? 'lunas' : 'belum_lunas',
            ));
          }
        }
        return list;
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<List<ProfitBreakdownRow>> fetchProfitBreakdown({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      final dailyRows = await fetchDailySummaries(start: start, end: end);
      final revenueByDate = <String, double>{};
      for (final r in dailyRows) {
        final key = r.date.toIso8601String().substring(0, 10);
        revenueByDate[key] = r.revenue;
      }

      final cogsByDate = <String, double>{};
      try {
        final cogsRes = await _client
            .from('wo_items')
            .select('qty, parts(cost_price), work_orders!inner(completed_at)')
            .eq('kind', 'part')
            .eq('work_orders.status', 'selesai')
            .gte('work_orders.completed_at', '${startStr}T00:00:00')
            .lte('work_orders.completed_at', '${endStr}T23:59:59');
        for (final item in cogsRes as List) {
          final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
          final partMap = item['parts'] as Map?;
          final cost = (partMap?['cost_price'] as num?)?.toDouble() ?? 0.0;
          final woMap = item['work_orders'] as Map?;
          final completedAtStr = woMap?['completed_at'] as String?;
          if (completedAtStr == null) continue;
          final dateKey = completedAtStr.substring(0, 10);
          cogsByDate[dateKey] = (cogsByDate[dateKey] ?? 0) + qty * cost;
        }
      } catch (_) {}

      final days = end.difference(start).inDays;
      final result = <ProfitBreakdownRow>[];
      for (int i = 0; i <= days; i++) {
        final d = DateTime(start.year, start.month, start.day)
            .add(Duration(days: i));
        final key = d.toIso8601String().substring(0, 10);
        final rev = revenueByDate[key] ?? 0.0;
        final cogs = cogsByDate[key] ?? 0.0;
        result.add(ProfitBreakdownRow(date: d, revenue: rev, cogs: cogs));
      }
      return result;
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<WoDoneRow>> fetchCompletedWorkOrders({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      final res = await _client
          .from('work_orders')
          .select(
              'id, wo_number, paid_amount, pay_method, completed_at, status, vehicles(plate_no, customers(name)), wo_items(id)')
          .eq('status', 'selesai')
          .gte('completed_at', '${startStr}T00:00:00')
          .lte('completed_at', '${endStr}T23:59:59')
          .order('completed_at', ascending: false);
      final list = <WoDoneRow>[];
      for (final m in res as List) {
        final vehicles = m['vehicles'] as Map?;
        String? plateNo;
        String? custName;
        if (vehicles != null) {
          plateNo = vehicles['plate_no'] as String?;
          final cust = vehicles['customers'];
          if (cust is Map) custName = cust['name'] as String?;
        }
        final items = m['wo_items'] as List?;
        list.add(WoDoneRow(
          id: m['id'] as String,
          woNumber: (m['wo_number'] as String?) ?? '',
          plateNo: plateNo,
          customerName: custName,
          completedAt: DateTime.parse(m['completed_at'].toString()),
          paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0.0,
          itemCount: items?.length ?? 0,
          status: m['status'] as String?,
          payMethod: m['pay_method'] as String?,
        ));
      }
      return list;
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<PartSoldDetailRow>> fetchPartsSoldDetail({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      final monthStart = DateTime(start.year, start.month, 1);

      // Primary: aggregate via part_movements (sumber v_top_parts)
      try {
        final res = await _client
            .from('part_movements')
            .select('part_id, qty, parts(name, sell_price)')
            .eq('direction', 'out')
            .eq('ref_type', 'wo')
            .gte('created_at', '${startStr}T00:00:00')
            .lte('created_at', '${endStr}T23:59:59');
        final grouped = <String, PartSoldDetailRow>{};
        for (final m in res as List) {
          final partId = m['part_id'] as String? ?? '';
          if (partId.isEmpty) continue;
          final qty = (m['qty'] as num?)?.toDouble() ?? 0.0;
          final partMap = m['parts'] as Map?;
          final name = (partMap?['name'] as String?) ?? 'Suku Cadang';
          final sellPrice = (partMap?['sell_price'] as num?)?.toDouble() ?? 0.0;
          final existing = grouped[partId];
          if (existing == null) {
            grouped[partId] = PartSoldDetailRow(
              partId: partId,
              name: name,
              qtyOut: qty,
              revenue: qty * sellPrice,
              monthStart: monthStart,
            );
          } else {
            grouped[partId] = PartSoldDetailRow(
              partId: partId,
              name: name,
              qtyOut: existing.qtyOut + qty,
              revenue: existing.revenue + qty * sellPrice,
              monthStart: monthStart,
            );
          }
        }
        if (grouped.isNotEmpty) {
          final sorted = grouped.values.toList()
            ..sort((a, b) => b.qtyOut.compareTo(a.qtyOut));
          return sorted;
        }
        // Jika part_movements kosong tapi v_daily_summary ada (legacy), fallback ke wo_items
      } catch (_) {
        // lanjut ke fallback wo_items
      }

      // Fallback: agregasi via wo_items (konsisten dengan v_daily_summary parts_out_qty)
      try {
        final woRes = await _client
            .from('wo_items')
            .select('part_id, qty, unit_price, parts(name, sell_price), work_orders!inner(completed_at, status)')
            .eq('kind', 'part')
            .eq('work_orders.status', 'selesai')
            .gte('work_orders.completed_at', '${startStr}T00:00:00')
            .lte('work_orders.completed_at', '${endStr}T23:59:59');
        final grouped = <String, PartSoldDetailRow>{};
        for (final m in woRes as List) {
          final partId = m['part_id'] as String? ?? '';
          if (partId.isEmpty) continue;
          final qty = (m['qty'] as num?)?.toDouble() ?? 0.0;
          final partMap = m['parts'] as Map?;
          final name = (partMap?['name'] as String?) ?? 'Suku Cadang';
          // prefer unit_price tercatat, fallback sell_price
          final unitPrice = (m['unit_price'] as num?)?.toDouble() ??
              (partMap?['sell_price'] as num?)?.toDouble() ??
              0.0;
          final existing = grouped[partId];
          if (existing == null) {
            grouped[partId] = PartSoldDetailRow(
              partId: partId,
              name: name,
              qtyOut: qty,
              revenue: qty * unitPrice,
              monthStart: monthStart,
            );
          } else {
            grouped[partId] = PartSoldDetailRow(
              partId: partId,
              name: name,
              qtyOut: existing.qtyOut + qty,
              revenue: existing.revenue + qty * unitPrice,
              monthStart: monthStart,
            );
          }
        }
        final sorted = grouped.values.toList()
          ..sort((a, b) => b.qtyOut.compareTo(a.qtyOut));
        return sorted;
      } catch (_) {
        return [];
      }
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<HppRow>> fetchHppDetail({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      try {
        final res = await _client
            .from('wo_items')
            .select(
                'qty, work_order_id, parts(cost_price), work_orders!inner(wo_number, completed_at, status)')
            .eq('kind', 'part')
            .eq('work_orders.status', 'selesai')
            .gte('work_orders.completed_at', '${startStr}T00:00:00')
            .lte('work_orders.completed_at', '${endStr}T23:59:59');
        final grouped = <String, HppRow>{};
        final itemCounts = <String, int>{};
        for (final item in res as List) {
          final woId = item['work_order_id'] as String? ?? '';
          if (woId.isEmpty) continue;
          final woMap = item['work_orders'] as Map?;
          final woNumber = (woMap?['wo_number'] as String?) ?? '';
          final completedAtStr = woMap?['completed_at'] as String?;
          final completedAt = completedAtStr != null
              ? DateTime.tryParse(completedAtStr) ?? start
              : start;
          final qty = (item['qty'] as num?)?.toDouble() ?? 0.0;
          final partMap = item['parts'] as Map?;
          final cost = (partMap?['cost_price'] as num?)?.toDouble() ?? 0.0;
          final cogs = qty * cost;
          final existing = grouped[woId];
          final count = (itemCounts[woId] ?? 0) + 1;
          itemCounts[woId] = count;
          if (existing == null) {
            grouped[woId] = HppRow(
              woId: woId,
              woNumber: woNumber,
              completedAt: completedAt,
              totalCogs: cogs,
              itemCount: count,
            );
          } else {
            grouped[woId] = HppRow(
              woId: woId,
              woNumber: woNumber,
              completedAt: completedAt,
              totalCogs: existing.totalCogs + cogs,
              itemCount: count,
            );
          }
        }
        final sorted = grouped.values.toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return sorted;
      } catch (_) {
        return [];
      }
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> markDebtPaid(String movementId) async {
    try {
      // 1. Try stored procedure if migration 0007 applied
      await _client.rpc('mark_debt_paid', params: {'p_movement_id': movementId});
    } catch (_) {
      try {
        // 2. Try direct column update
        await _client
            .from('part_movements')
            .update({
              'debt_status': 'lunas',
              'paid_at': DateTime.now().toIso8601String(),
            })
            .eq('id', movementId);
      } catch (_) {
        // 3. Fallback: append [LUNAS] to note so it won't be counted as unpaid debt
        try {
          final row = await _client
              .from('part_movements')
              .select('note')
              .eq('id', movementId)
              .maybeSingle();
          final currentNote = (row?['note'] as String?) ?? '';
          await _client
              .from('part_movements')
              .update({'note': '$currentNote [LUNAS]'.trim()})
              .eq('id', movementId);
        } catch (e) {
          throw RepositoryException(mapRepositoryError(e));
        }
      }
    }
  }
}

class FakeReportRepository implements ReportRepository {
  DashboardSummary? mockDashboardSummary;
  List<DailySummaryRow>? mockDailySummaries;
  List<TopPartRow>? mockTopParts;
  QueueCounts? mockQueueCounts;

  @override
  Future<DashboardSummary> fetchDashboardSummary() async {
    return mockDashboardSummary ??
        DashboardSummary(
          todayRevenue: 1500000,
          activeWoCount: 4,
          lowStockCount: 2,
          last7Days: List.generate(7, (i) {
            final d = DateTime.now().subtract(Duration(days: 6 - i));
            return DailySummaryRow(
              date: d,
              revenue: (i + 1) * 350000,
              woDoneCount: i + 1,
              partsOutQty: (i + 1) * 2,
            );
          }),
        );
  }

  @override
  Future<List<DailySummaryRow>> fetchDailySummaries({
    required DateTime start,
    required DateTime end,
  }) async {
    if (mockDailySummaries != null) return mockDailySummaries!;
    final days = end.difference(start).inDays + 1;
    return List.generate(days, (i) {
      final d = start.add(Duration(days: i));
      return DailySummaryRow(
        date: d,
        revenue: (i % 5 + 1) * 250000,
        woDoneCount: (i % 3) + 1,
        partsOutQty: (i % 4 + 1).toDouble(),
      );
    });
  }

  @override
  Future<List<TopPartRow>> fetchTopParts({required DateTime month}) async {
    if (mockTopParts != null) return mockTopParts!;
    final firstDay = DateTime(month.year, month.month, 1);
    return [
      TopPartRow(
        monthStart: firstDay,
        partId: 'p1',
        name: 'Oli Mesin 1L',
        qtyOut: 24,
        revenue: 2400000,
      ),
      TopPartRow(
        monthStart: firstDay,
        partId: 'p2',
        name: 'Filter Oli',
        qtyOut: 15,
        revenue: 750000,
      ),
      TopPartRow(
        monthStart: firstDay,
        partId: 'p3',
        name: 'Kampas Rem Depan',
        qtyOut: 8,
        revenue: 1600000,
      ),
    ];
  }

  @override
  Future<QueueCounts> fetchQueueCounts() async {
    return mockQueueCounts ??
        const QueueCounts(waiting: 2, inProgress: 2, done: 10);
  }

  OwnerFinancialSummary? mockFinancialSummary;
  List<DistributorDebtItem>? mockDistributorDebts;
  List<ProfitBreakdownRow>? mockProfitBreakdown;
  List<WoDoneRow>? mockWoDoneRows;
  List<PartSoldDetailRow>? mockPartSoldDetails;
  List<HppRow>? mockHppRows;

  @override
  Future<OwnerFinancialSummary> fetchOwnerFinancialSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    return mockFinancialSummary ??
        const OwnerFinancialSummary(
          totalRevenue: 2500000,
          totalCogs: 950000,
          totalUnpaidDebt: 750000,
        );
  }

  @override
  Future<List<DistributorDebtItem>> fetchDistributorDebts({String? status}) async {
    mockDistributorDebts ??= [
      DistributorDebtItem(
        movementId: 'm-debt-1',
        partId: 'p1',
        partName: 'Oli Mesin Fastron 1L',
        distributor: 'PT Pertamina Lubricants',
        qty: 12,
        purchasePrice: 62500,
        totalDebt: 750000,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().add(const Duration(days: 11)),
        debtStatus: 'belum_lunas',
      ),
    ];
    var list = List<DistributorDebtItem>.from(mockDistributorDebts!);
    if (status != null) {
      list = list.where((d) => d.debtStatus == status).toList();
    }
    return list;
  }

  @override
  Future<void> markDebtPaid(String movementId) async {
    mockDistributorDebts ??= [
      DistributorDebtItem(
        movementId: 'm-debt-1',
        partId: 'p1',
        partName: 'Oli Mesin Fastron 1L',
        distributor: 'PT Pertamina Lubricants',
        qty: 12,
        purchasePrice: 62500,
        totalDebt: 750000,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().add(const Duration(days: 11)),
        debtStatus: 'belum_lunas',
      ),
    ];
    mockDistributorDebts!.removeWhere((d) => d.movementId == movementId);
  }

  @override
  Future<List<ProfitBreakdownRow>> fetchProfitBreakdown({
    required DateTime start,
    required DateTime end,
  }) async {
    if (mockProfitBreakdown != null) return List.from(mockProfitBreakdown!);
    final days = end.difference(start).inDays + 1;
    return List.generate(days, (i) {
      final d = start.add(Duration(days: i));
      final revenue = (i % 5 + 1) * 250000.0;
      final cogs = (i % 3 + 1) * 90000.0;
      return ProfitBreakdownRow(date: d, revenue: revenue, cogs: cogs);
    });
  }

  @override
  Future<List<WoDoneRow>> fetchCompletedWorkOrders({
    required DateTime start,
    required DateTime end,
  }) async {
    if (mockWoDoneRows != null) return List.from(mockWoDoneRows!);
    final days = end.difference(start).inDays + 1;
    final count = days.clamp(1, 5);
    const methods = ['cash', 'transfer', 'qris'];
    return List.generate(count, (i) {
      final d = end.subtract(Duration(days: i));
      return WoDoneRow(
        id: 'wo-$i',
        woNumber: 'WO-2026-${100 + i}',
        plateNo: 'B ${1000 + i} XYZ',
        customerName: 'Pelanggan ${i + 1}',
        completedAt: d,
        paidAmount: (i + 1) * 500000,
        itemCount: (i % 3) + 1,
        status: 'selesai',
        payMethod: methods[i % methods.length],
      );
    });
  }

  @override
  Future<List<PartSoldDetailRow>> fetchPartsSoldDetail({
    required DateTime start,
    required DateTime end,
  }) async {
    if (mockPartSoldDetails != null) return List.from(mockPartSoldDetails!);
    final monthStart = DateTime(start.year, start.month, 1);
    return [
      PartSoldDetailRow(
        partId: 'p1',
        name: 'Oli Mesin 1L',
        qtyOut: 24,
        revenue: 2400000,
        monthStart: monthStart,
      ),
      PartSoldDetailRow(
        partId: 'p2',
        name: 'Filter Oli',
        qtyOut: 15,
        revenue: 750000,
        monthStart: monthStart,
      ),
      PartSoldDetailRow(
        partId: 'p3',
        name: 'Kampas Rem Depan',
        qtyOut: 8,
        revenue: 1600000,
        monthStart: monthStart,
      ),
    ];
  }

  @override
  Future<List<HppRow>> fetchHppDetail({
    required DateTime start,
    required DateTime end,
  }) async {
    if (mockHppRows != null) return List.from(mockHppRows!);
    final wos = await fetchCompletedWorkOrders(start: start, end: end);
    return List.generate(wos.length, (i) {
      final wo = wos[i];
      return HppRow(
        woId: wo.id,
        woNumber: wo.woNumber,
        completedAt: wo.completedAt,
        totalCogs: (i + 1) * 90000,
        itemCount: wo.itemCount,
      );
    });
  }
}
