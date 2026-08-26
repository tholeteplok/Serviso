import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF512D6D);
  static const primaryDim = Color(0xFF8E77A0);
  static const action = Color(0xFFF8485E);
  static const actionDim = Color(0xFFFA919E);
  static const teal = Color(0xFF00C1D4);
  static const tealDim = Color(0xFF66DAE5);

  static const canvas = Color(0xFFEEEEEE);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF241531);
  static const inkMuted = Color(0xFF6E6579);
  static const line = Color(0xFFE4E1E7);

  static Color tintOf(Color base) => base.withValues(alpha: 0.12);

  static const tintPrimary = Color(0x1F512D6D);
  static const tintTeal = Color(0x1F00C1D4);
  static const tintAction = Color(0x1FF8485E);
}
