import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Authentic tilted rubber stamp badge (-5° rotation),
/// with rounded corners (8px) and bold Kalam handwriting font.
/// Replicates the `.stamp` design signature from serviso-ops-dashboard.html.
class StatusStamp extends StatelessWidget {
  const StatusStamp({
    super.key,
    required this.label,
    required this.bgColor,
    this.textColor = AppColors.ink900,
    this.borderColor = AppColors.borderInk,
    this.borderWidth = 1.5,
    this.borderRadius,
    this.angle = -0.0872, // -5 degrees in radians
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final double angle;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget stamp = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.kalam(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );

    if (angle != 0.0) {
      stamp = Transform.rotate(
        angle: angle,
        child: stamp,
      );
    }

    return stamp;
  }
}
