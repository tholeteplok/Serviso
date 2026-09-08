import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/neo_app_bar.dart';
import '../../../../core/widgets/neo_bottom_sheet.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_search_bar.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';
import '../../pdf/laporan_export.dart';

class CustomerReportScreen extends ConsumerStatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  ConsumerState<CustomerReportScreen> createState() =>
      _CustomerReportScreenState();
}

class _CustomerReportScreenState extends ConsumerState<CustomerReportScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _searchController.text = ref.read(customerAnalyticsSearchProvider);
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(customerAnalyticsSearchProvider.notifier).state = '';
    setState(() => _searching = false);
  }

  Future<void> _handleExport(
    BuildContext context,
    List<CustomerAnalyticsRow> rows,
  ) async {
    try {
      final csv = buildCustomerCsv(rows);
      final filename =
          'laporan_pelanggan_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
      await shareCsv(csv, filename);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pelanggan berhasil diekspor')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor data: $e')),
        );
      }
    }
  }

  void _showSortSheet(BuildContext context, CustomerSortOption currentSort) {
    showNeoBottomSheet(
      context: context,
      title: 'Urutkan Pelanggan',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final opt in CustomerSortOption.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                opt.label,
                style: AppTypography.textTheme().bodyMedium?.copyWith(
                      fontWeight: opt == currentSort
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: opt == currentSort
                          ? AppColors.ink900
                          : AppColors.textSecondary,
                    ),
              ),
              leading: Icon(
                opt == currentSort
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: opt == currentSort
                    ? AppColors.ink900
                    : AppColors.borderInk,
                size: 20,
              ),
              onTap: () {
                ref.read(customerAnalyticsSortProvider.notifier).state = opt;
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Color _tierColor(CustomerLoyaltyTier tier) {
    switch (tier) {
      case CustomerLoyaltyTier.vip:
        return AppColors.pastelYellow;
      case CustomerLoyaltyTier.loyal:
        return AppColors.pastelMint;
      case CustomerLoyaltyTier.newCustomer:
        return AppColors.pastelBlue;
      case CustomerLoyaltyTier.prospect:
        return AppColors.bgSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final asyncStats = ref.watch(customerSummaryStatsProvider);
    final asyncFiltered = ref.watch(filteredCustomerAnalyticsProvider);
    final currentSort = ref.watch(customerAnalyticsSortProvider);
    final currentFilter = ref.watch(customerAnalyticsFilterProvider);

    final rowsForExport =
        asyncFiltered.valueOrNull ?? const <CustomerAnalyticsRow>[];

    return Scaffold(
      appBar: NeoAppBar(
        title: _searching ? '' : 'Pelanggan & CRM',
        bottom: _searching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: NeoSearchBar(
                    controller: _searchController,
                    hintText: 'Cari nama, HP, plat, alamat...',
                    autofocus: true,
                    onChanged: (val) => ref
                        .read(customerAnalyticsSearchProvider.notifier)
                        .state = val,
                    onClear: _closeSearch,
                  ),
                ),
              )
            : null,
        actions: [
          if (!_searching)
            IconButton(
              icon: Icon(AppIcons.search, color: AppColors.ink900),
              tooltip: 'Cari pelanggan',
              onPressed: _openSearch,
            ),
          PopupMenuButton<String>(
            tooltip: 'Export data',
            icon: Icon(AppIcons.share, color: AppColors.ink900),
            onSelected: (val) {
              if (val == 'csv') {
                _handleExport(context, rowsForExport);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'csv',
                child: Text('Export CSV / Excel'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerAnalyticsProvider);
          ref.invalidate(customerSummaryStatsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top Summary Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: asyncStats.when(
                  loading: () => const SizedBox(
                    height: 90,
                    child: Center(child: LinearProgressIndicator()),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (stats) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Pelanggan',
                              value: '${stats.totalCustomers}',
                              subtitle: 'Terdaftar di bengkel',
                              color: AppColors.pastelPurple,
                              icon: AppIcons.usersThree,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Aktif Bulan Ini',
                              value: '${stats.activeCustomersThisMonth}',
                              subtitle: 'Kunjungan <30 hari',
                              color: AppColors.pastelMint,
                              icon: AppIcons.checkCircle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Omset Pelanggan',
                              value: rupiah(stats.totalAccumulatedRevenue),
                              subtitle: 'Akumulasi seluruh belanja',
                              color: AppColors.pastelYellow,
                              icon: AppIcons.wallet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Rata-rata LTV',
                              value: rupiah(stats.averageLtv),
                              subtitle: 'Nilai per pelanggan',
                              color: AppColors.pastelBlue,
                              icon: AppIcons.report,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Filter & Sort Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final f in CustomerFilterOption.values)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(f.label),
                                      selected: currentFilter == f,
                                      selectedColor: AppColors.pastelMint,
                                      backgroundColor: AppColors.bgSurface,
                                      labelStyle: textTheme.bodySmall?.copyWith(
                                        color: AppColors.ink900,
                                        fontWeight: currentFilter == f
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.borderInk,
                                        width: 1.5,
                                      ),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: AppRadius.pill,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          ref
                                              .read(customerAnalyticsFilterProvider
                                                  .notifier)
                                              .state = f;
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showSortSheet(context, currentSort),
                          borderRadius: AppRadius.button,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: AppRadius.button,
                              border: Border.all(
                                color: AppColors.borderInk,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.borderInk,
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.filter,
                                  size: 16,
                                  color: AppColors.ink900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Urutkan',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Customer List
            asyncFiltered.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(customerAnalyticsProvider),
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  final isQueryEmpty = ref
                      .read(customerAnalyticsSearchProvider)
                      .trim()
                      .isNotEmpty;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(
                        icon: isQueryEmpty
                            ? AppIcons.search
                            : AppIcons.usersThree,
                        title: isQueryEmpty
                            ? 'Tidak ada pelanggan yang cocok'
                            : 'Belum ada data pelanggan',
                        message: isQueryEmpty
                            ? 'Coba ganti kata kunci pencarian atau filter segmentasi.'
                            : 'Data transaksi pelanggan akan tampil di sini secara otomatis.',
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final c = customers[index];
                        return _CustomerCard(
                          customer: c,
                          tierColor: _tierColor(c.tier),
                          onTap: () => context.push('/pelanggan/${c.id}'),
                        );
                      },
                      childCount: customers.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return NeoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderInk, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: AppColors.ink900),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.tierColor,
    required this.onTap,
  });

  final CustomerAnalyticsRow customer;
  final Color tierColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final lastVisitStr = customer.lastVisitAt != null
        ? dateShortId(customer.lastVisitAt!)
        : 'Belum pernah';

    return NeoCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Tier Badge, and Needs Reminder
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierColor,
                  border: Border.all(
                    color: AppColors.borderInk,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.ink900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Loyalty Tier Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor,
                            borderRadius: AppRadius.pill,
                            border: Border.all(
                              color: AppColors.borderInk,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            customer.tier.label,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink900,
                            ),
                          ),
                        ),
                        if (customer.needsReminder) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pastelPink,
                              borderRadius: AppRadius.pill,
                              border: Border.all(
                                color: AppColors.borderInk,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.clock,
                                  size: 10,
                                  color: AppColors.statusDanger,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Perlu Servis',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.statusDanger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.caretRight,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderHairline),
          const SizedBox(height: 10),

          // Contact Row
          if (customer.phone != null && customer.phone!.isNotEmpty) ...[
            Row(
              children: [
                Icon(AppIcons.phone, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  customer.phone!,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (customer.address != null &&
                    customer.address!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(AppIcons.home, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.address!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Grid Metrics: LTV, Kunjungan, Kendaraan, Terakhir
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderHairline, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Belanja (LTV)',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rupiah(customer.totalSpent),
                        style: AppTypography.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.borderHairline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kunjungan Terakhir',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastVisitStr,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Vehicle & Visits Detail
          Row(
            children: [
              Icon(AppIcons.car, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customer.plateNumbers.isNotEmpty
                      ? '${customer.vehicleCount} Kendaraan (${customer.plateNumbers.join(', ')})'
                      : '${customer.vehicleCount} Kendaraan',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.receipt,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.woCount} WO • ${customer.directSaleCount} Kasir',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Frequent items / products
          if (customer.topPurchases.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final item in customer.topPurchases)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                        color: AppColors.borderHairline,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.tag,
                          size: 10,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.ink900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
