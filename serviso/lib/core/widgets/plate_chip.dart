import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

class PlateChip extends StatelessWidget {
  const PlateChip({
    super.key,
    required this.plateText,
    this.textStyle,
  });

  final String plateText;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.chipSmall,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Text(
        plate(plateText),
        style: textStyle ??
            AppTypography.mono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}
