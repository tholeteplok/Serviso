import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Centralized Brand Icon component featuring the stylized Serviso logo
/// enclosed in a pastel mint pop-brutalist tactile container.
/// Ensures the white logo remains striking and legible across light/white backgrounds.
class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({
    super.key,
    this.size = 64.0,
    this.iconSize,
    this.backgroundColor = AppColors.pastelMint,
    this.borderRadius,
    this.borderWidth = 1.5,
    this.shadowOffset = 3.0,
  });

  final double size;
  final double? iconSize;
  final Color backgroundColor;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final double shadowOffset;

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (size * 0.6);
    final effectiveRadius = borderRadius ?? AppRadius.card;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: AppColors.borderStrong,
          width: borderWidth,
        ),
        boxShadow: shadowOffset > 0
            ? [
                BoxShadow(
                  color: AppColors.borderStrong,
                  offset: Offset(0, shadowOffset),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        AppAssets.appIcon,
        width: effectiveIconSize,
        height: effectiveIconSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
