import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_chart_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'chart_empty_box.dart';

/// Data point model for [NeoBarChart].
class NeoBarChartItem {
  const NeoBarChartItem({
    required this.label,
    required this.value,
    this.tooltipTitle,
    this.tooltipSubtitle,
    this.colorOverride,
  });

  final String label;
  final double value;
  final String? tooltipTitle;
  final String? tooltipSubtitle;
  final Color? colorOverride;
}

/// Centralized Neo-Brutalist Bar Chart adhering to Design System v2:
/// - 1.5px solid ink border on bars with top 8px radius
/// - Automatic Peak Detection (highest value gets solid Amber #FFC526 and ★ marker)
/// - Dynamic bar width and spacing based on item count (7 days vs 30 days filter)
/// - Dashed horizontal grid line #E8E0D6
/// - Custom tactile tooltip with mono font
class NeoBarChart extends StatelessWidget {
  const NeoBarChart({
    super.key,
    required this.items,
    this.height = 200,
    this.barWidth,
    this.valueFormatter,
    this.emptyTitle = 'Belum ada data periode ini',
    this.emptyMessage = 'Pilih rentang lain atau catat transaksi dulu.',
  });

  final List<NeoBarChartItem> items;
  final double height;
  final double? barWidth;
  final String Function(double value)? valueFormatter;
  final String emptyTitle;
  final String emptyMessage;

  double _resolveBarWidth(int count) {
    if (barWidth != null) return barWidth!;
    if (count <= 7) return 24.0;
    if (count <= 14) return 16.0;
    if (count <= 31) return 7.5;
    return 4.5;
  }

  BarChartAlignment _resolveAlignment(int count) {
    if (count <= 7) return BarChartAlignment.spaceEvenly;
    return BarChartAlignment.spaceAround;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ChartEmptyBox(
        title: emptyTitle,
        message: emptyMessage,
        height: height,
      );
    }

    final count = items.length;
    final effectiveBarWidth = _resolveBarWidth(count);
    final effectiveAlignment = _resolveAlignment(count);

    // Find peak (highest positive value)
    int peakIndex = -1;
    double maxVal = double.negativeInfinity;
    for (int i = 0; i < items.length; i++) {
      if (items[i].value > 0 && items[i].value > maxVal) {
        maxVal = items[i].value;
        peakIndex = i;
      }
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: effectiveAlignment,
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: AppChartTheme.dashedGridLine,
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
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final item = items[index];
                  final isPeak = index == peakIndex;

                  // For 30 days, skip some labels to prevent overcrowding
                  if (count > 14 && index % 5 != 0 && !isPeak && index != count - 1) {
                    return const SizedBox.shrink();
                  }

                  final peakSuffix = isPeak ? ' \u2605' : '';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${item.label}$peakSuffix',
                      style: AppTypography.mono(
                        fontSize: count > 14 ? 9 : 10,
                        fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
                        color: isPeak ? AppColors.ink900 : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppChartTheme.tooltipBg,
              tooltipBorder: const BorderSide(
                color: AppChartTheme.tooltipBorder,
                width: 1.5,
              ),
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= items.length) return null;
                final item = items[groupIndex];
                final formattedValue = valueFormatter != null
                    ? valueFormatter!(item.value)
                    : item.value.toStringAsFixed(0);

                final title = item.tooltipTitle ?? item.label;
                final isPeak = groupIndex == peakIndex;

                return BarTooltipItem(
                  '$title${isPeak ? ' (Tertinggi \u2605)' : ''}\n',
                  AppChartTheme.tooltipTitleStyle,
                  children: [
                    TextSpan(
                      text: formattedValue,
                      style: AppChartTheme.tooltipValueStyle.copyWith(
                        color: isPeak ? AppColors.amber : Colors.white,
                      ),
                    ),
                    if (item.tooltipSubtitle != null) ...[
                      TextSpan(
                        text: '\n${item.tooltipSubtitle}',
                        style: AppChartTheme.tooltipTitleStyle,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          barGroups: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isPeak = index == peakIndex;

            Color rodColor;
            if (item.colorOverride != null) {
              rodColor = item.colorOverride!;
            } else if (item.value < 0) {
              rodColor = AppChartTheme.seriesPink; // Laba minus / loss
            } else if (isPeak) {
              rodColor = AppChartTheme.seriesPeak; // Solid Amber #FFC526
            } else {
              rodColor = AppChartTheme.seriesPrimary; // Solid Mint #3FBE85
            }

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  color: rodColor,
                  width: effectiveBarWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8.0),
                  ),
                  borderSide: const BorderSide(
                    color: AppColors.borderInk,
                    width: 1.5,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}