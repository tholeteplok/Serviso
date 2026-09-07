import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle kalam({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.ink,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.kalam(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

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

  /// DS v3 tablet kasir: displayLarge 48 desktop, 40 di width <920
  static double displayLargeSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w < 920 ? 40 : 48;
  }

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
      displayLarge: kalam(fontSize: 42, fontWeight: FontWeight.w700),
      displayMedium: kalam(fontSize: 34, fontWeight: FontWeight.w700),
      displaySmall: kalam(fontSize: 28, fontWeight: FontWeight.w700),
      headlineLarge: kalam(fontSize: 26, fontWeight: FontWeight.w700),
      headlineMedium: kalam(fontSize: 22, fontWeight: FontWeight.w700),
      headlineSmall: kalam(fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge:
          kalam(fontSize: 18, fontWeight: FontWeight.w700, color: ink),
      titleMedium:
          base.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
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
