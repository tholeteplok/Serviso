import 'package:flutter/material.dart';

import 'app_colors.dart';

/// DS v2 — Warm Industrial Soft Brutalism: Hybrid shadows
/// Soft diffuse (empuk) + hard ink offset (tegas).
/// Spec: docs/serviso-design-system-v2.html -- soft brutalsim + L0-L3
abstract final class AppShadow {
  /// L0 — Soft only: surface lembut (sheet/divider) — 0 6px 18px 6%
  static const soft = BoxShadow(
    offset: Offset(0, 6),
    blurRadius: 18,
    spreadRadius: 0,
    color: Color(0x0F111111),
  );

  static const softLg = BoxShadow(
    offset: Offset(0, 16),
    blurRadius: 40,
    spreadRadius: 0,
    color: Color(0x1A111111), // 10%
  );

  /// L1 — Card hybrid: WO card / stok — soft 8/24 6% + hard 4px #111
  static const card = BoxShadow(
    offset: Offset(4, 4),
    blurRadius: 0,
    spreadRadius: 0,
    color: AppColors.ink900,
  );

  static const cardSoft = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
    color: Color(0x0F111111),
  );

  /// L2 — Modal hybrid: dialog / sheet — soft 16/40 10% + hard 6px #111
  static const modal = BoxShadow(
    offset: Offset(6, 6),
    blurRadius: 0,
    spreadRadius: 0,
    color: AppColors.ink900,
  );

  static const modalSoft = BoxShadow(
    offset: Offset(0, 16),
    blurRadius: 40,
    spreadRadius: 0,
    color: Color(0x1A111111),
  );

  /// L3 — Float: nav / toast depth — soft 20/48 12% + hard 8px #111
  static const floating = BoxShadow(
    offset: Offset(8, 8),
    blurRadius: 0,
    spreadRadius: 0,
    color: AppColors.ink900,
  );

  static const floatingSoft = BoxShadow(
    offset: Offset(0, 20),
    blurRadius: 48,
    spreadRadius: 0,
    color: Color(0x1F111111), // 12%
  );

  // Convenience lists matching CSS vars
  static const List<BoxShadow> l0 = [soft];
  static const List<BoxShadow> l1 = [cardSoft, card];
  static const List<BoxShadow> l2 = [modalSoft, modal];
  static const List<BoxShadow> l3 = [floatingSoft, floating];

  // Button specific — primary/amber: soft + 2px hard
  static const buttonHard = BoxShadow(
    offset: Offset(2, 2),
    blurRadius: 0,
    color: AppColors.ink900,
  );
  static const buttonHardPressed = BoxShadow(
    offset: Offset(1, 1),
    blurRadius: 0,
    color: AppColors.ink900,
  );
}
