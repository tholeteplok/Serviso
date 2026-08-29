import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.tintPrimary,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.statusProgress,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.tintPrimary,
      onSecondaryContainer: AppColors.ink,
      error: AppColors.action,
      onError: AppColors.surface,
      errorContainer: AppColors.actionDim,
      onErrorContainer: AppColors.action,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.borderSubtle,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.borderSubtle,
    );
    final textTheme = AppTypography.textTheme();

    OutlineInputBorder inputBorder(Color color, [double width = 1.0]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.chakra(fontSize: 20),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.borderHairline, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderHairline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          side: const BorderSide(color: AppColors.accentPrimaryBorder, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(0, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink900,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          side: const BorderSide(color: AppColors.borderHairline, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink900,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.accentPrimaryBorder, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        border: inputBorder(AppColors.borderHairline),
        enabledBorder: inputBorder(AppColors.borderHairline),
        focusedBorder: inputBorder(AppColors.ink900, 2.0),
        errorBorder: inputBorder(AppColors.action),
        focusedErrorBorder: inputBorder(AppColors.action, 2.0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pill,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.tintPrimary,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => (textTheme.labelMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.inkMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium
            ?.copyWith(color: AppColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
