import 'package:flutter/material.dart';

import '../models/wo_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final WoStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.borderInk,
          width: 1.5,
        ),
      ),
      child: Text(
        status.label,
        style: AppTypography.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
