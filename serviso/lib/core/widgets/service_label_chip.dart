import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class ServiceLabelChip extends StatelessWidget {
  const ServiceLabelChip({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.pastelMint,
    this.textStyle,
  });

  final String label;
  final Color backgroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.chipSmall,
        border: Border.all(color: AppColors.borderInk, width: 1.5),
      ),
      child: Text(
        label.trim().isEmpty ? 'Jasa / Layanan' : label.trim(),
        style: textStyle ??
            AppTypography.textTheme().labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
