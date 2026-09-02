import 'package:flutter/material.dart';

import '../theme/app_chart_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Item model for [HorizontalBarList].
class HorizontalBarItem {
  const HorizontalBarItem({
    required this.title,
    required this.value,
    required this.valueLabel,
    this.subtitle,
    this.colorOverride,
  });

  final String title;
  final double value;
  final String valueLabel;
  final String? subtitle;
  final Color? colorOverride;
}

/// Centralized ranking horizontal bar chart adhering to Design System v2:
/// - Track: #F5F1EB, 14px height, pill radius (999)
/// - Fill: solid colors from [AppChartTheme.rankPalette] + 1.5px right ink border
/// - Header: Title + Bold Mono count/quantity
/// - Subtitle: Mono pricing / detail
class HorizontalBarList extends StatelessWidget {
  const HorizontalBarList({
    super.key,
    required this.items,
    this.maxItems = 5,
    this.barHeight = 14,
  });

  final List<HorizontalBarItem> items;
  final int maxItems;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final displayItems = items.take(maxItems).toList();
    if (displayItems.isEmpty) return const SizedBox.shrink();

    // Find maximum value to calculate proportions
    final maxVal = displayItems.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (int i = 0; i < displayItems.length; i++) ...[
          _buildItem(displayItems[i], i, maxVal),
          if (i < displayItems.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildItem(HorizontalBarItem item, int index, double maxVal) {
    final ratio = maxVal > 0 ? (item.value / maxVal).clamp(0.05, 1.0) : 0.05;
    final color = item.colorOverride ??
        AppChartTheme.rankPalette[index % AppChartTheme.rankPalette.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.borderInk,
                  width: 1.0,
                ),
              ),
              child: Text(
                item.valueLabel,
                style: AppTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Progress track & bar
        Container(
          height: barHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1EB),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.borderHairline,
              width: 1.0,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                border: const Border(
                  right: BorderSide(
                    color: AppColors.borderInk,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (item.subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            item.subtitle!,
            style: AppTypography.mono(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}