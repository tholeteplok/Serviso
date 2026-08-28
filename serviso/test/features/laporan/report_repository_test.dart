import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';

void main() {
  late FakeReportRepository repo;

  setUp(() {
    repo = FakeReportRepository();
  });

  test('fetchDashboardSummary returns default mock summary', () async {
    final summary = await repo.fetchDashboardSummary();
    expect(summary.todayRevenue, 1500000);
    expect(summary.activeWoCount, 4);
    expect(summary.lowStockCount, 2);
    expect(summary.last7Days.length, 7);
  });

  test('fetchDailySummaries calculates date range correctly', () async {
    final start = DateTime(2026, 8, 20);
    final end = DateTime(2026, 8, 26);
    final list = await repo.fetchDailySummaries(start: start, end: end);
    expect(list.length, 7);
  });

  test('fetchTopParts returns mock list of top parts', () async {
    final list = await repo.fetchTopParts(month: DateTime.now());
    expect(list.length, 3);
    expect(list.first.name, 'Oli Mesin 1L');
  });

  test('fetchQueueCounts returns mock queue counts', () async {
    final counts = await repo.fetchQueueCounts();
    expect(counts.waiting, 2);
    expect(counts.inProgress, 2);
    expect(counts.done, 10);
  });
}
