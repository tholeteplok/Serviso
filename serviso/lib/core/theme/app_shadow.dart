import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Craftsman Field Ledger (v3.0): 2-Tier Elevation System
/// Tier 1: Flat Grounded (0px shadow) for dense repeated data (100+ inventory parts).
/// Tier 2: Warm Offset Shadow (Offset(3, 3) in #332E28 ~28%) for CTAs, active cards, and modals.
abstract final class AppShadow {
  /// Tier 1 — Flat Grounded: 0 shadow (dense lists, 100+ inventory cards, tables)
  static const List<BoxShadow> tier1Flat = <BoxShadow>[];
  static const List<BoxShadow> tier1 = tier1Flat;

  /// L0 — Soft diffuse ambient only
  static const soft = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 14,
    spreadRadius: 0,
    color: AppColors.shadowSubtle,
  );

  static const softLg = BoxShadow(
    offset: Offset(0, 10),
    blurRadius: 24,
    spreadRadius: 0,
    color: AppColors.shadowSubtle,
  );

  /// L1 / Tier 2 — Warm Offset Card: Active WO card, active cashier bill
  static const card = BoxShadow(
    offset: Offset(3, 3),
    blurRadius: 0,
    spreadRadius: 0,
    color: AppColors.shadowWarm,
  );

  static const cardSoft = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
    color: AppColors.shadowSubtle,
  );

  /// L2 — Modal / Dialog
  static const modal = BoxShadow(
    offset: Offset(4, 4),
    blurRadius: 0,
    spreadRadius: 0,
    color: AppColors.shadowWarm,
  );

  static const modalSoft = BoxShadow(
    offset: Offset(0, 10),
    blurRadius: 24,
    spreadRadius: 0,
    color: AppColors.shadowSubtle,
  );

  /// L3 — Floating navigation bar / toast
  static const floating = BoxShadow(
    offset: Offset(4, 4),
    blurRadius: 0,
    spreadRadius: 0,
    color: AppColors.shadowWarm,
  );

  static const floatingSoft = BoxShadow(
    offset: Offset(0, 12),
    blurRadius: 28,
    spreadRadius: 0,
    color: AppColors.shadowSubtle,
  );

  // Convenience lists
  static const List<BoxShadow> l0 = [soft];
  static const List<BoxShadow> l1 = [card];
  static const List<BoxShadow> l2 = [modal];
  static const List<BoxShadow> l3 = [floating];
  static const List<BoxShadow> tier2 = [card];

  // Button specific — primary/amber: warm offset 3px normal, 1px pressed
  static const buttonHard = BoxShadow(
    offset: Offset(3, 3),
    blurRadius: 0,
    color: AppColors.shadowWarm,
  );
  static const buttonHardPressed = BoxShadow(
    offset: Offset(1, 1),
    blurRadius: 0,
    color: AppColors.shadowWarm,
  );
}
