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

  test('fetchOwnerFinancialSummary returns revenue, cogs, and net profit', () async {
    final start = DateTime(2026, 8, 20);
    final end = DateTime(2026, 8, 26);
    final fin = await repo.fetchOwnerFinancialSummary(start: start, end: end);
    expect(fin.totalRevenue, 2500000);
    expect(fin.totalCogs, 950000);
    expect(fin.netProfit, 1550000);
    expect(fin.totalUnpaidDebt, 750000);
  });

  test('fetchDistributorDebts and markDebtPaid work properly', () async {
    final debts = await repo.fetchDistributorDebts(status: 'belum_lunas');
    expect(debts.length, 1);
    expect(debts.first.distributor, 'PT Pertamina Lubricants');
    expect(debts.first.totalDebt, 750000);

    await repo.markDebtPaid(debts.first.movementId);
    final after = await repo.fetchDistributorDebts(status: 'belum_lunas');
    expect(after, isEmpty);

    final allDebts = await repo.fetchDistributorDebts();
    expect(allDebts.length, 1);
    expect(allDebts.first.isSettled, true);
  });
}
