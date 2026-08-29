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

  Future<List<DistributorDebtItem>> fetchDistributorDebts();

  Future<void> markDebtPaid(String movementId);
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
            .select('qty, purchase_price')
            .eq('payment_type', 'hutang')
            .eq('debt_status', 'belum_lunas');
        for (final d in debtsRes as List) {
          final q = (d['qty'] as num?)?.toDouble() ?? 0.0;
          final p = (d['purchase_price'] as num?)?.toDouble() ?? 0.0;
          totalUnpaid += q * p;
        }
      } catch (_) {
        // Safe fallback
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
  Future<List<DistributorDebtItem>> fetchDistributorDebts() async {
    try {
      final res = await _client
          .from('part_movements')
          .select('id, part_id, qty, purchase_price, distributor, created_at, due_date, debt_status, parts(name)')
          .eq('payment_type', 'hutang')
          .eq('debt_status', 'belum_lunas')
          .order('created_at', ascending: false);

      return (res as List).map((m) {
        final partMap = m['parts'] as Map?;
        final pName = (partMap?['name'] as String?) ?? 'Suku Cadang';
        final qty = (m['qty'] as num?)?.toDouble() ?? 0.0;
        final price = (m['purchase_price'] as num?)?.toDouble() ?? 0.0;
        return DistributorDebtItem(
          movementId: m['id'] as String,
          partId: m['part_id'] as String,
          partName: pName,
          distributor: (m['distributor'] as String?) ?? 'Distributor Umum',
          qty: qty,
          purchasePrice: price,
          totalDebt: qty * price,
          createdAt: DateTime.parse(m['created_at'].toString()),
          dueDate: m['due_date'] != null ? DateTime.tryParse(m['due_date'].toString()) : null,
          debtStatus: (m['debt_status'] as String?) ?? 'belum_lunas',
        );
      }).toList();
    } catch (_) {
      return [];
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
  Future<List<DistributorDebtItem>> fetchDistributorDebts() async {
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
    return List.from(mockDistributorDebts!);
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
}
