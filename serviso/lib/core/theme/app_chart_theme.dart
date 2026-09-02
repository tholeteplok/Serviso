import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Centralized tokens, palettes, and styling rules for charts
/// aligned with Serviso Design System v2 (04c — Chart & Statistik).
abstract final class AppChartTheme {
  // ---------------------------------------------------------------------------
  // Data Palette (DS v2 04c)
  // ---------------------------------------------------------------------------
  /// Series 1 / Primary / Selesai / Revenue (#3FBE85)
  static const Color seriesPrimary = AppColors.accentPrimary;

  /// Highlight / Peak Value / Menunggu (#FFC526)
  static const Color seriesPeak = AppColors.amber;

  /// Series 2 / Tren / Dikerjakan (#A9D3FF)
  static const Color seriesBlue = AppColors.pastelBlue;

  /// Series 3 / Batal / Laba Negatif / Alert (#FFB5C1)
  static const Color seriesPink = AppColors.pastelPink;

  /// Series 4 / Kategori Tambahan (#D6C7FF)
  static const Color seriesLilac = AppColors.pastelPurple;

  /// Series Palette for Multi-item / Ranking visualizations
  static const List<Color> rankPalette = [
    seriesPrimary, // Rank 1: Mint
    seriesBlue,    // Rank 2: Blue
    seriesPeak,    // Rank 3: Amber
    seriesLilac,   // Rank 4: Lilac
    seriesPink,    // Rank 5: Pink
  ];

  // ---------------------------------------------------------------------------
  // Grid & Axis Lines
  // ---------------------------------------------------------------------------
  /// Grid line color (#E8E0D6 - subtle hairline)
  static const Color gridColor = AppColors.borderHairline;

  /// Dashed horizontal grid line generator
  static FlLine dashedGridLine(double val) => const FlLine(
        color: gridColor,
        strokeWidth: 1.0,
        dashArray: [4, 4],
      );

  // ---------------------------------------------------------------------------
  // Neo-Brutalist Tooltip Decoration
  // ---------------------------------------------------------------------------
  /// Background color for tooltips (#111111 dark for peak/contrast or #FFFFFF)
  static const Color tooltipBg = AppColors.ink900;
  static const Color tooltipBorder = AppColors.borderInk;

  /// Tooltip text style
  static TextStyle tooltipTitleStyle = AppTypography.mono(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: const Color(0xFFEDE9E3),
  );

  static TextStyle tooltipValueStyle = AppTypography.mono(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFFFFFFF),
  );
}