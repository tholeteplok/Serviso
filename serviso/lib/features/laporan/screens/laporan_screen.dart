import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/report_controllers.dart';
import '../models/report_models.dart';

class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    final period = ref.watch(laporanPeriodProvider);
    final dailySummariesAsync = ref.watch(laporanDailySummariesProvider);
    final topPartsAsync = ref.watch(topPartsProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final ownerFinancialAsync =
        isAdmin ? ref.watch(ownerFinancialSummaryProvider) : null;
    final debtsAsync = isAdmin ? ref.watch(distributorDebtsProvider) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Analisis'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(laporanDailySummariesProvider);
          ref.invalidate(topPartsProvider);
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
              activeColor: AppColors.pastelMint,
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
                  return const EmptyState(
                    icon: Icons.bar_chart_rounded,
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
                                      color: AppColors.primary,
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
                                      color: AppColors.teal,
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
                                      title: 'Modal Part (HPP)',
                                      value: rupiah(fin.totalCogs),
                                      subtitle: 'Modal pokok barang',
                                      icon: AppIcons.part,
                                      color: AppColors.inkMuted,
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
                                          ? AppColors.action
                                          : AppColors.teal,
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
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Total Omset',
                              value: rupiah(totalRevenue),
                              subtitle: 'Pendapatan kotor',
                              icon: AppIcons.wallet,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
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
                              color: AppColors.teal,
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
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bar Chart Section
                    SectionCard(
                      title: 'Grafik Pendapatan Harian',
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            gridData: const FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine:
                                  _getLaporanHorizontalLine,
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= rows.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = rows[index].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '${date.day}/${date.month}',
                                        style: AppTypography.mono(
                                          fontSize: 10,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: rows.asMap().entries.map((entry) {
                              final index = entry.key;
                              final row = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: row.revenue,
                                    color: AppColors.primary,
                                    width: 16,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Top Parts Section
            topPartsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
              data: (parts) {
                if (parts.isEmpty) return const SizedBox.shrink();

                return SectionCard(
                  title: 'Suku Cadang Terlaris Bulan Ini',
                  child: Column(
                    children: parts.map((part) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' pcs terjual',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              rupiah(part.revenue),
                              style: AppTypography.mono(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // Khusus Owner: Section Hutang Distributor
            if (isAdmin && debtsAsync != null) ...[
              const SizedBox(height: 16),
              debtsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => const SizedBox.shrink(),
                data: (debts) {
                  return SectionCard(
                    title: 'Daftar Hutang Distributor (Tempo)',
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Perbarui Data Hutang',
                      onPressed: () {
                        ref.invalidate(distributorDebtsProvider);
                        ref.invalidate(ownerFinancialSummaryProvider);
                      },
                    ),
                    child: debts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.teal,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Tidak ada hutang distributor yang belum lunas. Semua kewajiban telah terbayar!',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: debts
                                .map((d) => _buildDebtItemCard(context, ref, d))
                                .toList(),
                          ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebtItemCard(
    BuildContext context,
    WidgetRef ref,
    DistributorDebtItem debt,
  ) {
    final textTheme = AppTypography.textTheme();
    final isPastDue = debt.dueDate != null &&
        debt.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return NeoCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: isPastDue ? AppColors.statusCancelled : AppColors.borderStrong,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPastDue
                  ? AppColors.action.withValues(alpha: 0.12)
                  : AppColors.inkMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: isPastDue ? AppColors.action : AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.distributor,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${debt.partName} • ${debt.qty} pcs',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                if (debt.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Jatuh Tempo: ${dateShortId(debt.dueDate!)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: isPastDue ? AppColors.action : AppColors.inkMuted,
                      fontWeight:
                          isPastDue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rupiah(debt.totalDebt),
                style: AppTypography.mono(
                  fontWeight: FontWeight.bold,
                  color: AppColors.action,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Pelunasan Hutang'),
                      content: Text(
                        'Konfirmasi pelunasan hutang ke "${debt.distributor}" sebesar ${rupiah(debt.totalDebt)}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Ya, Lunasi'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref
                          .read(reportRepositoryProvider)
                          .markDebtPaid(debt.movementId);
                      ref.invalidate(distributorDebtsProvider);
                      ref.invalidate(ownerFinancialSummaryProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hutang distributor berhasil dilunasi'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  }
                },
                child: const Text('Lunasi'),
              ),
            ],
          ),
        ],
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
  }) {
    return NeoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme().bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.textTheme().labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                          fontSize: 10,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

FlLine _getLaporanHorizontalLine(double val) => const FlLine(
      color: AppColors.line,
      strokeWidth: 1,
    );
