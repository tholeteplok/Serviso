import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../controllers/report_controllers.dart';

class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    final period = ref.watch(laporanPeriodProvider);
    final dailySummariesAsync = ref.watch(laporanDailySummariesProvider);
    final topPartsAsync = ref.watch(topPartsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Analisis'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(laporanDailySummariesProvider);
          ref.invalidate(topPartsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Segmented Period Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.line.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: LaporanPeriod.values.map((p) {
                  final isSelected = p == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(laporanPeriodProvider.notifier).state = p;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          p.label,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                onRetry: () => ref.invalidate(laporanDailySummariesProvider),
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Total Omset',
                            value: rupiah(totalRevenue),
                            icon: Icons.payments_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'WO Selesai',
                            value: '$totalWo WO',
                            icon: Icons.task_alt_rounded,
                            color: AppColors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Part Terjual',
                            value: '${totalPartsOut.toStringAsFixed(0)} Pcs',
                            icon: Icons.settings_input_component_outlined,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
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
                              getDrawingHorizontalLine: _getLaporanHorizontalLine,
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
                            barGroups: rows.asMap().entries.map((e) {
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.revenue,
                                    color: AppColors.primary,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(4),
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
              data: (topParts) {
                if (topParts.isEmpty) return const SizedBox.shrink();
                return SectionCard(
                  title: 'Suku Cadang Terlaris Bulan Ini',
                  child: Column(
                    children: topParts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: index < topParts.length - 1
                              ? const Border(
                                  bottom: BorderSide(color: AppColors.line),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: index == 0
                                  ? AppColors.primary
                                  : AppColors.line,
                              child: Text(
                                '${index + 1}',
                                style: AppTypography.mono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    'Terjual ${item.qtyOut.toStringAsFixed(0)} pcs',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              rupiah(item.revenue),
                              style: AppTypography.mono(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.teal,
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
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.textTheme().bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.mono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

FlLine _getLaporanHorizontalLine(double val) => const FlLine(
      color: AppColors.line,
      strokeWidth: 1,
    );

