import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // 2.1 Base Tokens — Craftsman Field Ledger (v3.0)
  // ---------------------------------------------------------------------------
  /// Canvas background for main screens (#FAF6F0 - warm paper linen)
  static const bgBase = Color(0xFFFAF6F0);

  /// Card, sheet, modal background (#FFFFFF - clean paper)
  static const bgSurface = Color(0xFFFFFFFF);

  /// Subtle card, secondary module background (#FFFDF9 - soft parchment)
  static const bgSurfaceSubtle = Color(0xFFFFFDF9);

  /// Primary dark ink (#332E28 - warm deep charcoal, eliminates visual fatigue)
  static const inkPrimary = Color(0xFF332E28);
  static const ink900 = inkPrimary;

  /// Secondary text color, subtitles, captions (#6C665F - WCAG AA 4.5:1)
  static const textSecondary = Color(0xFF6C665F);

  /// Subtle hairline divider & passive card outline (#E8E2D8)
  static const borderHairline = Color(0xFFE8E2D8);

  /// Warm shadow tokens (Tier 2 elevated actions)
  static const shadowWarm = Color(0x47332E28); // ~28% warm charcoal
  static const shadowSubtle = Color(0x1F332E28); // ~12% warm charcoal

  // ---------------------------------------------------------------------------
  // 2.2 Pastel Palette (Soft Highlighter Wash)
  // ---------------------------------------------------------------------------
  static const pastelCream = Color(0xFFFFF3EF);
  static const pastelYellow = Color(0xFFFEF3C7);
  static const pastelAmber = pastelYellow;
  static const pastelPink = Color(0xFFFFE4E6);
  static const pastelMint = Color(0xFF9ADBB3);
  static const pastelBlue = Color(0xFFE0F2FE);
  static const pastelPurple = Color(0xFFEDE9FE);

  // ---------------------------------------------------------------------------
  // 2.3 Functional Status Tokens (Fill Pastel, Border selalu inkPrimary #332E28)
  // ---------------------------------------------------------------------------
  /// Waiting / Menunggu (Yellow Pastel)
  static const statusWaiting = Color(0xFFFEF3C7);
  static const statusWaitingBorder = inkPrimary;

  /// In progress / Dikerjakan (Blue Pastel)
  static const statusProgress = Color(0xFFE0F2FE);
  static const statusProgressBorder = inkPrimary;

  /// Done / Selesai / Lunas (Mint Pastel)
  static const statusDone = Color(0xFF9ADBB3);
  static const statusDoneBorder = inkPrimary;

  /// Cancelled / Dibatalkan / Critical Alert (Pink Pastel)
  static const statusCancelled = Color(0xFFFFE4E6);
  static const statusCancelledBorder = inkPrimary;

  /// Danger / Error / Critical text or icon (#E8748A)
  static const statusDanger = Color(0xFFE8748A);

  // ---------------------------------------------------------------------------
  // 2.4 Accents (Solid Charcoal Primary + Warm Cream Text)
  // ---------------------------------------------------------------------------
  /// Primary CTA button, active navigation (#332E28 - solid warm charcoal)
  static const accentPrimary = Color(0xFF332E28);
  static const accentPrimaryBorder = inkPrimary;
  static const onPrimary = Color(0xFFFAF6F0);

  /// Highlights, secondary buttons, badges (#FFE59A)
  static const accentSecondary = Color(0xFFFFE59A);
  static const accentSecondaryBorder = ink900;

  /// Solid Mint accent alias (#3FBE85)
  static const accentMint = Color(0xFF3FBE85);
  static const accentMintBorder = ink900;

  // ---------------------------------------------------------------------------
  // 2.5 Amber Accent — DS v2 Dual-Accent System (Mint primary + Amber secondary)
  // ---------------------------------------------------------------------------
  /// Solid Amber — DS v2: --amber: #FFC526 (secondary CTA, highlight, badge)
  static const amber = Color(0xFFFFC526);
  static const amberPress = Color(0xFFE8AE12);  // DS v2: --amber-press
  static const amberDim = Color(0xFFFFE9A6);    // DS v2: tint for focus ring
  // Canonical v2 name — keep `amber` as alias for backwards compat
  static const accentAmber = amber;
  static const accentAmberBorder = ink900;
  static const accentAmberPress = amberPress;

  // ---------------------------------------------------------------------------
  // 2.5 Universal Line-Art Border (Seluruh card, button, chip, chart)
  // ---------------------------------------------------------------------------
  static const borderInk = ink900;

  // ---------------------------------------------------------------------------
  // Dark Surface (Headers / Navigation)
  // ---------------------------------------------------------------------------
  static const surfaceDark = Color(0xFF141414); // DS v2: --graphite
  static const textOnDark = Color(0xFFFDF7F2);

  // ---------------------------------------------------------------------------
  // Backwards-Compatibility Aliases (smooth migration across codebase)
  // ---------------------------------------------------------------------------
  static const borderStrong = ink900;
  static const textPrimary = ink900;
  static const borderSubtle = borderHairline;
  static const shadowHard = ink900;

  static const primary = accentPrimary;
  static const primaryDim = pastelPurple;
  static const action = Color(0xFFE8748A);
  static const actionDim = pastelPink;
  static const teal = Color(0xFF3FBE85);
  static const tealDim = pastelMint;

  // Bottom Navigation Pill Bar (Design Spec §6.6 — Clean white container)
  static const navBarBg = bgSurface;
  static const navBarActive = accentPrimary; // Solid Mint active pill

  static const canvas = bgBase;
  static const surface = bgSurface;
  static const ink = ink900;
  static const inkMuted = textSecondary;
  static const line = borderStrong;

  static Color tintOf(Color base) => base.withValues(alpha: 0.12);

  static const tintPrimary = Color(0x1F111111);
  static const tintTeal = Color(0x1F5FB98C);
  static const tintAction = Color(0x1FE8748A);
}
