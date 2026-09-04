import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/horizontal_bar_list.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_bar_chart.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/router/app_router.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/report_controllers.dart';

class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(laporanPeriodProvider);
    final dailySummariesAsync = ref.watch(laporanDailySummariesProvider);
    final topPartsAsync = ref.watch(topPartsProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final ownerFinancialAsync =
        isAdmin ? ref.watch(ownerFinancialSummaryProvider) : null;

    return Scaffold(
      appBar: const NeoAppBar(
        title: 'Laporan & Analisis',
        showBack: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(laporanDailySummariesProvider);
          ref.invalidate(topPartsProvider);
          ref.invalidate(dailyRevenueByMethodProvider);
          if (isAdmin) {
            ref.invalidate(ownerFinancialSummaryProvider);
            ref.invalidate(distributorDebtsProvider);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Segmented Period Selector
            NeoSegmentControl<LaporanPeriod>(
              selectedValue: period,
              onValueChanged: (p) {
                ref.read(laporanPeriodProvider.notifier).state = p;
              },
              items: LaporanPeriod.values
                  .map((p) => NeoSegmentItem<LaporanPeriod>(
                        value: p,
                        label: p.label,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Daily Summaries Section
            dailySummariesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => ErrorView(
                message: err.toString(),
                onRetry: () {
                  ref.invalidate(laporanDailySummariesProvider);
                  if (isAdmin) {
                    ref.invalidate(ownerFinancialSummaryProvider);
                    ref.invalidate(distributorDebtsProvider);
                  }
                },
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return EmptyState(
                    icon: AppIcons.report,
                    title: 'Belum Ada Data Laporan',
                    message:
                        'Transaksi selesai akan secara otomatis tercatat di sini.',
                  );
                }

                final totalRevenue = rows.fold<double>(
                  0.0,
                  (sum, r) => sum + r.revenue,
                );
                final totalWo = rows.fold<int>(
                  0,
                  (sum, r) => sum + r.woDoneCount,
                );
                final totalDirectSales = rows.fold<int>(
                  0,
                  (sum, r) => sum + r.directSaleCount,
                );
                final totalPartsOut = rows.fold<double>(
                  0.0,
                  (sum, r) => sum + r.partsOutQty,
                );

                return Column(
                  children: [
                    // Summary Metric Cards
                    if (isAdmin && ownerFinancialAsync != null) ...[
                      ownerFinancialAsync.when(
                        data: (fin) => Column(
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      context,
                                      title: 'Total Omset',
                                      value: rupiah(fin.totalRevenue),
                                      subtitle: 'Pendapatan kotor',
                                      icon: AppIcons.wallet,
                                      color: AppColors.pastelPurple,
                                      onTap: () => context.push(
                                        AppRoutes.laporanOmset,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      context,
                                      title: 'Untung Bersih',
                                      value: rupiah(fin.netProfit),
                                      subtitle: 'Omzet - Modal Part',
                                      icon: AppIcons.report,
                                      color: AppColors.pastelMint,
                                      onTap: () {
                                        if (!isAdmin) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Hanya pemilik dapat membuka rincian ini',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        context.push(AppRoutes.laporanLaba);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      context,
                                      title: 'Penjualan Langsung',
                                      value: '$totalDirectSales Transaksi',
                                      subtitle: 'Penjualan kasir',
                                      icon: AppIcons.money,
                                      color: AppColors.pastelYellow,
                                      onTap: () => context.push(
                                        AppRoutes.laporanPenjualanLangsung,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      context,
                                      title: 'Hutang Distributor',
                                      value: rupiah(fin.totalUnpaidDebt),
                                      subtitle: 'Tagihan belum lunas',
                                      icon: AppIcons.receipt,
                                      color: fin.totalUnpaidDebt > 0
                                          ? AppColors.pastelPink
                                          : AppColors.pastelMint,
                                      onTap: () {
                                        if (!isAdmin) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Hanya pemilik dapat membuka rincian ini',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        context.push(AppRoutes.laporanHutang);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: LinearProgressIndicator(),
                          ),
                        ),
                        error: (_, _) => Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Total Omset',
                                value: rupiah(totalRevenue),
                                subtitle: 'Pendapatan kotor',
                                icon: AppIcons.wallet,
                                color: AppColors.pastelPurple,
                                onTap: () => context.push(
                                  AppRoutes.laporanOmset,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Total Omset',
                                value: rupiah(totalRevenue),
                                subtitle: 'Pendapatan kotor',
                                icon: AppIcons.wallet,
                                color: AppColors.pastelPurple,
                                onTap: () => context.push(
                                  AppRoutes.laporanOmset,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                title: 'Penjualan Langsung',
                                value: '$totalDirectSales Transaksi',
                                subtitle: 'Penjualan kasir',
                                icon: AppIcons.money,
                                color: AppColors.pastelYellow,
                                onTap: () => context.push(
                                  AppRoutes.laporanPenjualanLangsung,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'WO Selesai',
                              value: '$totalWo WO',
                              subtitle: 'Pekerjaan tuntas',
                              icon: AppIcons.checkCircle,
                              color: AppColors.pastelMint,
                              onTap: () => context.push(
                                AppRoutes.laporanWoSelesai,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Part Terjual',
                              value: '${totalPartsOut.toStringAsFixed(0)} Pcs',
                              subtitle: 'Item suku cadang',
                              icon: AppIcons.inventory,
                              color: AppColors.pastelBlue,
                              onTap: () => context.push(
                                AppRoutes.laporanPartTerjual,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bar Chart Section
                    SectionCard(
                      title: 'Grafik Pendapatan Harian',
                      child: NeoBarChart(
                        items: rows.map((r) {
                          final date = r.date;
                          return NeoBarChartItem(
                            label: '${date.day}/${date.month}',
                            value: r.revenue,
                            tooltipTitle: '${date.day}/${date.month}/${date.year}',
                            tooltipSubtitle: '${r.totalTransactions} Transaksi • ${r.partsOutQty.toInt()} Part',
                          );
                        }).toList(),
                        valueFormatter: (val) => rupiah(val),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Rekap Metode Pembayaran per periode (Fase2/3)
            _MethodBreakdownSection(period: period),
            const SizedBox(height: 16),

            // Top Parts Section
            topPartsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(AppIcons.alertCircle, color: AppColors.statusDanger, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Gagal muat top parts: ${err.toString().replaceFirst('Exception: ', '')}',
                        style: AppTypography.textTheme().labelSmall?.copyWith(color: AppColors.statusDanger),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(topPartsProvider),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Coba'),
                    ),
                  ],
                ),
              ),
              data: (parts) {
                if (parts.isEmpty) return const SizedBox.shrink();

                return SectionCard(
                  title: 'Suku Cadang Terlaris Bulan Ini',
                  child: HorizontalBarList(
                    items: parts.map((part) {
                      return HorizontalBarItem(
                        title: part.name,
                        value: part.qtyOut,
                        valueLabel: '${part.qtyOut.toInt()}×',
                        subtitle: '${rupiah(part.revenue)} • ${part.qtyOut.toInt()} pcs terjual',
                      );
                    }).toList(),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return NeoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: icon & judul + chevron
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.button,
                  border: Border.all(color: AppColors.borderInk, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.ink900, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme().bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.1,
                      ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  AppIcons.caretRight,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Baris 2: nominal — full width, auto-shrink agar tidak terpotong
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.mono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            // Baris 3: keterangan tambahan
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme().labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontSize: 10,
                    height: 1.2,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodBreakdownSection extends ConsumerWidget {
  const _MethodBreakdownSection({required this.period});
  final LaporanPeriod period;

  ({DateTime start, DateTime end}) _range(LaporanPeriod p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (p) {
      case LaporanPeriod.days7:
        return (start: today.subtract(const Duration(days: 6)), end: today);
      case LaporanPeriod.days30:
        return (start: today.subtract(const Duration(days: 29)), end: today);
      case LaporanPeriod.thisMonth:
        return (start: DateTime(now.year, now.month, 1), end: today);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = _range(period);
    final async = ref.watch(dailyRevenueByMethodProvider((start: range.start, end: range.end)));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final totals = <String, double>{'cash': 0, 'transfer': 0, 'qris': 0};
        for (final r in rows) {
          final k = r.payMethod ?? 'cash';
          totals[k] = (totals[k] ?? 0) + r.revenue;
        }
        final hasAny = totals.values.any((v) => v > 0);
        if (!hasAny) return const SizedBox.shrink();
        return SectionCard(
          title: 'Rekap Metode Pembayaran',
          child: Row(
            children: [
              _methodMiniCard(context, 'Tunai', rupiah(totals['cash'] ?? 0), AppColors.pastelMint),
              const SizedBox(width: 8),
              _methodMiniCard(context, 'Transfer', rupiah(totals['transfer'] ?? 0), AppColors.pastelBlue),
              const SizedBox(width: 8),
              _methodMiniCard(context, 'QRIS', rupiah(totals['qris'] ?? 0), AppColors.pastelYellow),
            ],
          ),
        );
      },
    );
  }

  Widget _methodMiniCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: AppRadius.button,
          border: Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        child: Column(
          children: [
            Text(label, style: AppTypography.textTheme().labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
