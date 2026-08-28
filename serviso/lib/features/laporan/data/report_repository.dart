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
}
