import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // 2.1 Base Tokens — aligned with DS v2 "Warm Industrial Soft Brutalism"
  // ---------------------------------------------------------------------------
  /// Canvas background for main screens (#F9F5EF - warm grey-cream) — DS v2: --bg
  static const bgBase = Color(0xFFF9F5EF);

  /// Card, sheet, modal background (#FFFFFF) — DS v2: --surface
  static const bgSurface = Color(0xFFFFFFFF);

  /// Primary dark ink (#111111 - studio brand contrast) — DS v2: --fg, --border-strong
  static const ink900 = Color(0xFF111111);

  /// Secondary text color, subtitles, captions (#5E5E62) — DS v2: --muted, WCAG AA 4.5:1
  static const textSecondary = Color(0xFF5E5E62);

  /// Subtle hairline divider & passive card outline — DS v2: #E8E0D6 (was ECE6DF)
  static const borderHairline = Color(0xFFE8E0D6);

  // ---------------------------------------------------------------------------
  // 2.2 Pastel Palette
  // ---------------------------------------------------------------------------
  static const pastelCream = Color(0xFFFFF3EF);
  static const pastelYellow = Color(0xFFFFE59A);
  static const pastelPink = Color(0xFFFFB5C1);
  static const pastelMint = Color(0xFFB7E1D0);
  static const pastelBlue = Color(0xFFA9D3FF);
  static const pastelPurple = Color(0xFFD6C7FF);

  // ---------------------------------------------------------------------------
  // 2.3 Functional Status Tokens (Fill Pastel, Border selalu ink900)
  // ---------------------------------------------------------------------------
  /// Waiting / Menunggu (Yellow Pastel)
  static const statusWaiting = Color(0xFFFFE59A);
  static const statusWaitingBorder = ink900;

  /// In progress / Dikerjakan (Blue Pastel)
  static const statusProgress = Color(0xFFA9D3FF);
  static const statusProgressBorder = ink900;

  /// Done / Selesai / Lunas (Mint Pastel)
  static const statusDone = Color(0xFFB7E1D0);
  static const statusDoneBorder = ink900;

  /// Cancelled / Dibatalkan / Critical Alert (Pink Pastel)
  static const statusCancelled = Color(0xFFFFB5C1);
  static const statusCancelledBorder = ink900;

  // ---------------------------------------------------------------------------
  // 2.4 Accents (Solid Mint Primary + Pastel Yellow Secondary)
  // ---------------------------------------------------------------------------
  /// Primary CTA button, active navigation (#3FBE85 - Solid Mint)
  static const accentPrimary = Color(0xFF3FBE85);
  static const accentPrimaryBorder = ink900;

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
  static const primaryDim = pastelMint;
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
