import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_segment_control.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../auth/controllers/session_controller.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';
import '../../pdf/laporan_export.dart';

final profitDetailPeriodProvider =
    StateProvider<LaporanPeriod>((ref) => LaporanPeriod.days7);

({DateTime start, DateTime end}) _profitRange(LaporanPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case LaporanPeriod.days7:
      return (start: now.subtract(const Duration(days: 6)), end: now);
    case LaporanPeriod.days30:
      return (start: now.subtract(const Duration(days: 29)), end: now);
    case LaporanPeriod.thisMonth:
      return (start: DateTime(now.year, now.month, 1), end: now);
  }
}

FlLine _getProfitHorizontalLine(double _) => const FlLine(
      color: AppColors.line,
      strokeWidth: 1,
    );

class ProfitDetailScreen extends ConsumerWidget {
  const ProfitDetailScreen({super.key});

  Future<void> _handleExport(
    BuildContext context,
    List<ProfitBreakdownRow> rows,
    String periodLabel,
    String type,
  ) async {
    try {
      if (type == 'pdf') {
        final bytes = await buildProfitPdf(
          rows: rows,
          periodLabel: periodLabel,
          exportedAt: DateTime.now(),
        );
        final name =
            'laporan_laba_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildProfitCsv(rows);
        final name =
            'laporan_laba_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF Laba berhasil diekspor'
                  : 'CSV Laba berhasil diekspor',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rincian Laba')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.lock,
              title: 'Akses Terbatas',
              message:
                  'Hanya pemilik dapat melihat rincian laba bersih. Hubungi pemilik bengkel.',
              actionLabel: 'Kembali',
              onAction: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    }

    final period = ref.watch(profitDetailPeriodProvider);
    final range = _profitRange(period);
    final periodLabel = period.label;
    final asyncRows = ref
        .watch(profitBreakdownProvider((start: range.start, end: range.end)));
    final rowsForExport = asyncRows.valueOrNull ?? const <ProfitBreakdownRow>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Laba'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export',
            onSelected: (value) =>
                _handleExport(context, rowsForExport, periodLabel, value),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: NeoSegmentControl<LaporanPeriod>(
              selectedValue: period,
              onValueChanged: (p) =>
                  ref.read(profitDetailPeriodProvider.notifier).state = p,
              activeColor: AppColors.pastelMint,
              items: LaporanPeriod.values
                  .map((p) => NeoSegmentItem<LaporanPeriod>(
                        value: p,
                        label: p.label,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncRows.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(
                  profitBreakdownProvider((start: range.start, end: range.end)),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 32),
                      EmptyState(
                        icon: Icons.bar_chart_rounded,
                        title: 'Belum Ada Data Laba',
                        message:
                            'Tidak ada data laba pada periode ini. Coba ganti periode.',
                      ),
                    ],
                  );
                }

                final totalOmset =
                    rows.fold<double>(0, (s, r) => s + r.revenue);
                final totalHpp = rows.fold<double>(0, (s, r) => s + r.cogs);
                final totalLaba = rows.fold<double>(0, (s, r) => s + r.profit);
                final avgMargin =
                    totalOmset == 0 ? 0.0 : totalLaba / totalOmset * 100;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Summary 4 cards (2 rows)
                    Row(
                      children: [
                        Expanded(
                          child: _ProfitSummaryCard(
                            title: 'Total Omset',
                            value: rupiah(totalOmset),
                            subtitle: '${rows.length} hari',
                            color: AppColors.primary,
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfitSummaryCard(
                            title: 'Total HPP',
                            value: rupiah(totalHpp),
                            subtitle: 'modal part',
                            color: AppColors.inkMuted,
                            icon: Icons.inventory_2_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfitSummaryCard(
                            title: 'Total Laba',
                            value: rupiah(totalLaba),
                            subtitle: '${avgMargin.toStringAsFixed(1)}% margin',
                            color: totalLaba >= 0 ? AppColors.teal : AppColors.action,
                            icon: totalLaba >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfitSummaryCard(
                            title: 'Margin Rata-rata',
                            value: '${avgMargin.toStringAsFixed(1)}%',
                            subtitle: totalLaba >= 0 ? 'profit' : 'rugi',
                            color: AppColors.teal,
                            icon: Icons.percent_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Grafik Laba Harian',
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            gridData: const FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: _getProfitHorizontalLine,
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
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= rows.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final d = rows[idx].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${d.day}/${d.month}',
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
                            barGroups: rows.asMap().entries.map((e) {
                              final idx = e.key;
                              final r = e.value;
                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: r.profit,
                                    color: r.profit >= 0
                                        ? AppColors.teal
                                        : AppColors.action,
                                    width: 14,
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
                    const SizedBox(height: 16),
                    Text(
                      'Rincian Harian',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...rows.map((r) {
                      final margin =
                          r.revenue == 0 ? 0.0 : r.profit / r.revenue * 100;
                      final isPositive = r.profit >= 0;
                      return NeoCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (isPositive
                                        ? AppColors.teal
                                        : AppColors.action)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 20,
                                color: isPositive
                                    ? AppColors.teal
                                    : AppColors.action,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateShortId(r.date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Omset ${rupiah(r.revenue)} • HPP ${rupiah(r.cogs)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.inkMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Margin ${margin.toStringAsFixed(1)}%',
                                    style: AppTypography.mono(
                                      fontSize: 11,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  rupiah(r.profit),
                                  style: AppTypography.mono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isPositive
                                        ? AppColors.teal
                                        : AppColors.action,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${margin.toStringAsFixed(1)}%',
                                  style: AppTypography.mono(
                                    fontSize: 11,
                                    color: isPositive
                                        ? AppColors.teal
                                        : AppColors.action,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitSummaryCard extends StatelessWidget {
  const _ProfitSummaryCard({
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
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
