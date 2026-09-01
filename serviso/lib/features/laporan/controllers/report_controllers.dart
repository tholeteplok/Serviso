import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../workorders/controllers/work_order_providers.dart';
import '../data/report_repository.dart';
import '../models/report_models.dart';

enum LaporanPeriod {
  days7('7 Hari'),
  days30('30 Hari'),
  thisMonth('Bulan Ini');

  final String label;
  const LaporanPeriod(this.label);
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (AppConfig.isConfigured) {
    return SupabaseReportRepository(Supabase.instance.client);
  }
  return FakeReportRepository();
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  // Auto-recalculate whenever work orders change in real-time
  ref.watch(boardControllerProvider);
  return repo.fetchDashboardSummary();
});

final laporanPeriodProvider = StateProvider<LaporanPeriod>((ref) {
  return LaporanPeriod.days7;
});

final laporanDailySummariesProvider =
    FutureProvider<List<DailySummaryRow>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final period = ref.watch(laporanPeriodProvider);
  final now = DateTime.now();

  late DateTime start;
  late DateTime end;

  switch (period) {
    case LaporanPeriod.days7:
      start = now.subtract(const Duration(days: 6));
      end = now;
      break;
    case LaporanPeriod.days30:
      start = now.subtract(const Duration(days: 29));
      end = now;
      break;
    case LaporanPeriod.thisMonth:
      start = DateTime(now.year, now.month, 1);
      end = now;
      break;
  }

  return repo.fetchDailySummaries(start: start, end: end);
});

final topPartsProvider = FutureProvider<List<TopPartRow>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchTopParts(month: DateTime.now());
});

final ownerFinancialSummaryProvider =
    FutureProvider<OwnerFinancialSummary>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final period = ref.watch(laporanPeriodProvider);
  ref.watch(boardControllerProvider);
  final now = DateTime.now();

  late DateTime start;
  late DateTime end;

  switch (period) {
    case LaporanPeriod.days7:
      start = now.subtract(const Duration(days: 6));
      end = now;
      break;
    case LaporanPeriod.days30:
      start = now.subtract(const Duration(days: 29));
      end = now;
      break;
    case LaporanPeriod.thisMonth:
      start = DateTime(now.year, now.month, 1);
      end = now;
      break;
  }

  return repo.fetchOwnerFinancialSummary(start: start, end: end);
});

final distributorDebtsProvider =
    FutureProvider<List<DistributorDebtItem>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchDistributorDebts();
});

final debtPaymentsProvider = FutureProvider.family<List<DebtPaymentRecord>, String>(
  (ref, movementId) async {
    final repo = ref.watch(reportRepositoryProvider);
    return repo.fetchDebtPayments(movementId);
  },
);

final profitBreakdownProvider = FutureProvider.family<
    List<ProfitBreakdownRow>, ({DateTime start, DateTime end})>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchProfitBreakdown(start: range.start, end: range.end);
});

final woDoneDetailProvider = FutureProvider.family<
    List<WoDoneRow>, ({DateTime start, DateTime end})>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchCompletedWorkOrders(start: range.start, end: range.end);
});

final partsSoldDetailProvider = FutureProvider.family<
    List<PartSoldDetailRow>, ({DateTime start, DateTime end})>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchPartsSoldDetail(start: range.start, end: range.end);
});

final hppDetailProvider = FutureProvider.family<
    List<HppRow>, ({DateTime start, DateTime end})>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchHppDetail(start: range.start, end: range.end);
});

final dailyRevenueByMethodProvider = FutureProvider.family<
    List<DailyRevenueByMethodRow>, ({DateTime start, DateTime end})>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchDailyRevenueByPayMethod(start: range.start, end: range.end);
});

final transactionsProvider = FutureProvider.family<
    List<TransactionRow>, ({DateTime start, DateTime end})>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchTransactions(start: range.start, end: range.end);
});
