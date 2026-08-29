import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle chakra({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.ink,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.chakraPetch(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.ink,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle inter({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.ink,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextTheme textTheme({
    Color ink = AppColors.ink,
    Color inkMuted = AppColors.inkMuted,
  }) {
    final base =
        GoogleFonts.interTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );
    return base.copyWith(
      displayLarge: chakra(fontSize: 48, fontWeight: FontWeight.w700),
      displayMedium: chakra(fontSize: 40, fontWeight: FontWeight.w700),
      displaySmall: chakra(fontSize: 34, fontWeight: FontWeight.w700),
      headlineLarge: chakra(fontSize: 30, fontWeight: FontWeight.w700),
      headlineMedium: chakra(fontSize: 26, fontWeight: FontWeight.w700),
      headlineSmall: chakra(fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge:
          base.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: ink),
      titleMedium:
          base.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: ink),
      titleSmall:
          base.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: ink),
      bodyLarge: base.bodyLarge?.copyWith(color: ink),
      bodyMedium: base.bodyMedium?.copyWith(color: ink),
      bodySmall: base.bodySmall?.copyWith(color: ink),
      labelLarge:
          base.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: ink),
      labelMedium: base.labelMedium?.copyWith(color: inkMuted),
      labelSmall: base.labelSmall?.copyWith(color: inkMuted),
    );
  }
}
