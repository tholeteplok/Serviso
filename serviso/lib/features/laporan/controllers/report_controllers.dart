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

final directSalesDetailPeriodProvider =
    StateProvider<LaporanPeriod>((ref) => LaporanPeriod.days7);

final directSalesDetailProvider = FutureProvider.family<
    List<DirectSaleReportRow>, ({DateTime start, DateTime end})>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchDirectSalesDetail(start: range.start, end: range.end);
});

final customerAnalyticsProvider =
    FutureProvider<List<CustomerAnalyticsRow>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchCustomerAnalytics();
});

final customerSummaryStatsProvider =
    FutureProvider<CustomerSummaryStats>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchCustomerSummaryStats();
});

final customerAnalyticsSortProvider =
    StateProvider<CustomerSortOption>((ref) => CustomerSortOption.latestVisit);

final customerAnalyticsFilterProvider =
    StateProvider<CustomerFilterOption>((ref) => CustomerFilterOption.all);

final customerAnalyticsSearchProvider =
    StateProvider<String>((ref) => '');

final filteredCustomerAnalyticsProvider =
    Provider<AsyncValue<List<CustomerAnalyticsRow>>>((ref) {
  final asyncList = ref.watch(customerAnalyticsProvider);
  final sort = ref.watch(customerAnalyticsSortProvider);
  final filter = ref.watch(customerAnalyticsFilterProvider);
  final query = ref.watch(customerAnalyticsSearchProvider).trim().toLowerCase();

  return asyncList.whenData((list) {
    var filtered = list;

    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        final matchName = c.name.toLowerCase().contains(query);
        final matchPhone = c.phone?.toLowerCase().contains(query) ?? false;
        final matchAddress = c.address?.toLowerCase().contains(query) ?? false;
        final matchPlate =
            c.plateNumbers.any((p) => p.toLowerCase().contains(query));
        return matchName || matchPhone || matchAddress || matchPlate;
      }).toList();
    }

    switch (filter) {
      case CustomerFilterOption.all:
        break;
      case CustomerFilterOption.vip:
        filtered =
            filtered.where((c) => c.tier == CustomerLoyaltyTier.vip).toList();
        break;
      case CustomerFilterOption.active30:
        filtered = filtered.where((c) => c.isActiveRecently).toList();
        break;
      case CustomerFilterOption.needsReminder:
        filtered = filtered.where((c) => c.needsReminder).toList();
        break;
    }

    final sorted = List<CustomerAnalyticsRow>.from(filtered);
    switch (sort) {
      case CustomerSortOption.latestVisit:
        sorted.sort((a, b) {
          if (a.lastVisitAt == null && b.lastVisitAt == null) return 0;
          if (a.lastVisitAt == null) return 1;
          if (b.lastVisitAt == null) return -1;
          return b.lastVisitAt!.compareTo(a.lastVisitAt!);
        });
        break;
      case CustomerSortOption.oldestVisit:
        sorted.sort((a, b) {
          if (a.lastVisitAt == null && b.lastVisitAt == null) return 0;
          if (a.lastVisitAt == null) return 1;
          if (b.lastVisitAt == null) return -1;
          return a.lastVisitAt!.compareTo(b.lastVisitAt!);
        });
        break;
      case CustomerSortOption.nameAsc:
        sorted.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case CustomerSortOption.nameDesc:
        sorted.sort((a, b) =>
            b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case CustomerSortOption.highestSpend:
        sorted.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case CustomerSortOption.mostVisits:
        sorted.sort((a, b) => b.totalVisits.compareTo(a.totalVisits));
        break;
    }

    return sorted;
  });
});

// -----------------------------------------------------------------------------
// WO Selesai Search, Filter & Sort
// -----------------------------------------------------------------------------

enum WoPayMethodFilter { all, cash, qris, transfer }

extension WoPayMethodFilterX on WoPayMethodFilter {
  String get label => switch (this) {
        WoPayMethodFilter.all => 'Semua',
        WoPayMethodFilter.cash => 'Tunai',
        WoPayMethodFilter.qris => 'QRIS',
        WoPayMethodFilter.transfer => 'Transfer',
      };
}

enum WoDoneSortOption { latestDate, oldestDate, highestAmount, lowestAmount }

extension WoDoneSortOptionX on WoDoneSortOption {
  String get label => switch (this) {
        WoDoneSortOption.latestDate => 'Tanggal Terbaru',
        WoDoneSortOption.oldestDate => 'Tanggal Terlama',
        WoDoneSortOption.highestAmount => 'Nominal Tertinggi',
        WoDoneSortOption.lowestAmount => 'Nominal Terendah',
      };
}

final woDoneSearchProvider = StateProvider<String>((ref) => '');
final woDoneMethodFilterProvider =
    StateProvider<WoPayMethodFilter>((ref) => WoPayMethodFilter.all);
final woDoneSortProvider =
    StateProvider<WoDoneSortOption>((ref) => WoDoneSortOption.latestDate);

final filteredWoDoneDetailProvider = Provider.family<
    AsyncValue<List<WoDoneRow>>, ({DateTime start, DateTime end})>((ref, range) {
  final baseAsync = ref.watch(woDoneDetailProvider(range));
  final query = ref.watch(woDoneSearchProvider).trim().toLowerCase();
  final methodFilter = ref.watch(woDoneMethodFilterProvider);
  final sortOption = ref.watch(woDoneSortProvider);

  return baseAsync.whenData((list) {
    var result = list;
    if (query.isNotEmpty) {
      result = result.where((r) {
        final matchWo = r.woNumber.toLowerCase().contains(query);
        final matchPlate = (r.plateNo ?? '').toLowerCase().contains(query);
        final matchCustomer = (r.customerName ?? '').toLowerCase().contains(query);
        final matchVehicle = (r.vehicleDesc ?? '').toLowerCase().contains(query);
        return matchWo || matchPlate || matchCustomer || matchVehicle;
      }).toList();
    }

    if (methodFilter != WoPayMethodFilter.all) {
      final targetMethod = methodFilter.name;
      result = result.where((r) => r.payMethod?.toLowerCase() == targetMethod).toList();
    }

    final sorted = List<WoDoneRow>.from(result);
    switch (sortOption) {
      case WoDoneSortOption.latestDate:
        sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        break;
      case WoDoneSortOption.oldestDate:
        sorted.sort((a, b) => a.completedAt.compareTo(b.completedAt));
        break;
      case WoDoneSortOption.highestAmount:
        sorted.sort((a, b) => b.paidAmount.compareTo(a.paidAmount));
        break;
      case WoDoneSortOption.lowestAmount:
        sorted.sort((a, b) => a.paidAmount.compareTo(b.paidAmount));
        break;
    }
    return sorted;
  });
});


