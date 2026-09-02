import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_chart_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'chart_empty_box.dart';

/// Data point for [NeoLineChart].
class NeoLineChartPoint {
  const NeoLineChartPoint({
    required this.x,
    required this.y,
    required this.label,
    this.tooltipTitle,
    this.tooltipSubtitle,
  });

  final double x;
  final double y;
  final String label;
  final String? tooltipTitle;
  final String? tooltipSubtitle;
}

/// Centralized Neo-Brutalist Line/Area Chart adhering to Design System v2:
/// - 2.4px solid Mint stroke line (#3FBE85)
/// - 12% solid Mint area fill below line (no purple gradient)
/// - Normal dots: white circle with 1.5px Mint border
/// - Peak dot: 5px solid Amber circle (#FFC526) with 1.5px Ink border
/// - Dashed horizontal grid lines (#E8E0D6)
/// - Tactile neo-brutalist tooltip
class NeoLineChart extends StatelessWidget {
  const NeoLineChart({
    super.key,
    required this.points,
    this.height = 180,
    this.valueFormatter,
    this.emptyTitle = 'Belum ada data transaksi',
    this.emptyMessage = 'Transaksi akan muncul di grafik setelah dicatat.',
  });

  final List<NeoLineChartPoint> points;
  final double height;
  final String Function(double value)? valueFormatter;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return ChartEmptyBox(
        title: emptyTitle,
        message: emptyMessage,
        height: height,
      );
    }

    // Find peak (highest positive y value)
    int peakIndex = -1;
    double maxY = double.negativeInfinity;
    for (int i = 0; i < points.length; i++) {
      if (points[i].y > 0 && points[i].y > maxY) {
        maxY = points[i].y;
        peakIndex = i;
      }
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
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
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final point = points[index];
                  final isPeak = index == peakIndex;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      isPeak ? '${point.label} ★' : point.label,
                      style: AppTypography.mono(
                        fontSize: 10,
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
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppChartTheme.tooltipBg,
              tooltipBorder: const BorderSide(
                color: AppChartTheme.tooltipBorder,
                width: 1.5,
              ),
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= points.length) return null;

                  final point = points[index];
                  final formattedValue = valueFormatter != null
                      ? valueFormatter!(point.y)
                      : point.y.toStringAsFixed(0);

                  final title = point.tooltipTitle ?? point.label;
                  final isPeak = index == peakIndex;

                  return LineTooltipItem(
                    '$title${isPeak ? ' (Tertinggi ★)' : ''}\n',
                    AppChartTheme.tooltipTitleStyle,
                    children: [
                      TextSpan(
                        text: formattedValue,
                        style: AppChartTheme.tooltipValueStyle.copyWith(
                          color: isPeak ? AppColors.amber : Colors.white,
                        ),
                      ),
                      if (point.tooltipSubtitle != null) ...[
                        TextSpan(
                          text: '\n${point.tooltipSubtitle}',
                          style: AppChartTheme.tooltipTitleStyle,
                        ),
                      ],
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points.map((p) => FlSpot(p.x, p.y)).toList(),
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppChartTheme.seriesPrimary,
              barWidth: 2.4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isPeak = index == peakIndex;
                  if (isPeak) {
                    return FlDotCirclePainter(
                      radius: 5.0,
                      color: AppChartTheme.seriesPeak,
                      strokeWidth: 1.5,
                      strokeColor: AppColors.borderInk,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: Colors.white,
                    strokeWidth: 1.5,
                    strokeColor: AppChartTheme.seriesPrimary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppChartTheme.seriesPrimary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}