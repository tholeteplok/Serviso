import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // 2.1 Base Tokens (Soft UI + Neo-Brutalism)
  // ---------------------------------------------------------------------------
  /// Canvas background for main screens (#F7F8FA)
  static const bgBase = Color(0xFFF7F8FA);

  /// Card, sheet, modal background (#FFFFFF)
  static const bgSurface = Color(0xFFFFFFFF);

  /// Solid thick border characteristic of neo-brutalism (#1E2327)
  static const borderStrong = Color(0xFF1E2327);

  /// Primary text color (#1E2327)
  static const textPrimary = Color(0xFF1E2327);

  /// Secondary text color, subtitles, captions (#6B7280)
  static const textSecondary = Color(0xFF6B7280);

  /// Subtle section dividers (#E5E7EB)
  static const borderSubtle = Color(0xFFE5E7EB);

  // ---------------------------------------------------------------------------
  // 2.2 Functional Status Tokens (1:1 with Kanban & operational signals)
  // ---------------------------------------------------------------------------
  /// Waiting / Menunggu (#FFB020 - Orange)
  static const statusWaiting = Color(0xFFFFB020);

  /// In progress / Dikerjakan (#3B82F6 - Blue)
  static const statusProgress = Color(0xFF3B82F6);

  /// Done / Selesai / Lunas (#22C55E - Mint Green)
  static const statusDone = Color(0xFF22C55E);

  /// Cancelled / Dibatalkan / Critical Alert (#EF4444 - Coral Red)
  static const statusCancelled = Color(0xFFEF4444);

  // ---------------------------------------------------------------------------
  // 2.3 Accents
  // ---------------------------------------------------------------------------
  /// Primary CTA button, active navigation (#22C55E)
  static const accentPrimary = Color(0xFF22C55E);

  /// Highlights, notifications, badges (#FFB020)
  static const accentSecondary = Color(0xFFFFB020);

  // ---------------------------------------------------------------------------
  // 2.4 Dark Surface (Headers / Navigation)
  // ---------------------------------------------------------------------------
  static const surfaceDark = Color(0xFF1E2327);
  static const textOnDark = Color(0xFFF7F8FA);

  // ---------------------------------------------------------------------------
  // Neo-Brutalism Hard Shadow
  // ---------------------------------------------------------------------------
  static const shadowHard = Color(0xE61E2327); // rgba(30, 35, 39, 0.9)

  // ---------------------------------------------------------------------------
  // Backwards-Compatibility Aliases (smooth migration across codebase)
  // ---------------------------------------------------------------------------
  static const primary = accentPrimary;
  static const primaryDim = Color(0xFFDCFCE7);
  static const action = statusCancelled;
  static const actionDim = Color(0xFFFEE2E2);
  static const teal = statusDone;
  static const tealDim = Color(0xFFDCFCE7);

  static const canvas = bgBase;
  static const surface = bgSurface;
  static const ink = textPrimary;
  static const inkMuted = textSecondary;
  static const line = borderStrong;

  static Color tintOf(Color base) => base.withValues(alpha: 0.12);

  static const tintPrimary = Color(0x1F22C55E);
  static const tintTeal = Color(0x1F22C55E);
  static const tintAction = Color(0x1FEF4444);
}
