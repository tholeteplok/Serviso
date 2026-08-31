import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // 2.1 Base Tokens (Soft Pastel UI)
  // ---------------------------------------------------------------------------
  /// Canvas background for main screens (#FDF7F2 - warm cream)
  static const bgBase = Color(0xFFFDF7F2);

  /// Card, sheet, modal background (#FFFFFF)
  static const bgSurface = Color(0xFFFFFFFF);

  /// Primary dark ink (#111111 - studio brand contrast)
  static const ink900 = Color(0xFF111111);

  /// Secondary text color, subtitles, captions (#6E6E6E) — WCAG AA 4.5:1
  static const textSecondary = Color(0xFF6E6E6E);

  /// Subtle hairline divider & passive card outline (#ECE6DF)
  static const borderHairline = Color(0xFFECE6DF);

  // ---------------------------------------------------------------------------
  // 2.2 Pastel Palette
  // ---------------------------------------------------------------------------
  static const pastelCream = Color(0xFFFFF3EF);
  static const pastelYellow = Color(0xFFFFE59A);
  static const pastelPink = Color(0xFFFFB5C1);
  static const pastelMint = Color(0xFFB7E1D0);
  static const pastelBlue = Color(0xFFA9D3FF);

  // ---------------------------------------------------------------------------
  // 2.3 Functional Status Tokens (Fill Pastel + Darker Shade for Bottom Border)
  // ---------------------------------------------------------------------------
  /// Waiting / Menunggu (Yellow Pastel)
  static const statusWaiting = Color(0xFFFFE59A);
  static const statusWaitingBorder = Color(0xFFE0B94D);

  /// In progress / Dikerjakan (Blue Pastel)
  static const statusProgress = Color(0xFFA9D3FF);
  static const statusProgressBorder = Color(0xFF5B9AE8);

  /// Done / Selesai / Lunas (Mint Pastel)
  static const statusDone = Color(0xFFB7E1D0);
  static const statusDoneBorder = Color(0xFF5FB98C);

  /// Cancelled / Dibatalkan / Critical Alert (Pink Pastel)
  static const statusCancelled = Color(0xFFFFB5C1);
  static const statusCancelledBorder = Color(0xFFE8748A);

  // ---------------------------------------------------------------------------
  // 2.4 Accents (Primary Dark Ink + Secondary Pastel Yellow)
  // ---------------------------------------------------------------------------
  /// Primary CTA button, active navigation (#111111 with #000000 bottom border)
  static const accentPrimary = Color(0xFF111111);
  static const accentPrimaryBorder = Color(0xFF000000);

  /// Highlights, secondary buttons, badges (#FFE59A)
  static const accentSecondary = Color(0xFFFFE59A);
  static const accentSecondaryBorder = Color(0xFFE0B94D);

  /// Optional Solid Mint accent (#3FBE85)
  static const accentMint = Color(0xFF3FBE85);
  static const accentMintBorder = Color(0xFF2E9966);

  // ---------------------------------------------------------------------------
  // Dark Surface (Headers / Navigation)
  // ---------------------------------------------------------------------------
  static const surfaceDark = Color(0xFF111111);
  static const textOnDark = Color(0xFFFDF7F2);

  // ---------------------------------------------------------------------------
  // Backwards-Compatibility Aliases (smooth migration across codebase)
  // ---------------------------------------------------------------------------
  static const borderStrong = ink900;
  static const textPrimary = ink900;
  static const borderSubtle = borderHairline;
  static const shadowHard = accentPrimaryBorder;

  static const primary = accentPrimary;
  static const primaryDim = pastelMint;
  static const action = statusCancelledBorder;
  static const actionDim = pastelPink;
  static const teal = statusDoneBorder;
  static const tealDim = pastelMint;

  // Bottom Navigation Pill Bar (Reference Style)
  static const navBarBg = Color(0xFFB7E1D0); // Pastel Mint container
  static const navBarActive = Color(0xFFFFE59A); // Pastel Yellow active box

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
