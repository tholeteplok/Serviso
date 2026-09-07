import 'package:flutter/material.dart';

import '../models/wo_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

import 'status_stamp.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.isPressable = false,
    this.isStamp = true,
    this.onTap,
  });

  final WoStatus status;
  final bool isPressable;
  final bool isStamp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget chip;
    if (isStamp) {
      chip = StatusStamp(
        label: status.label,
        bgColor: status.bgColor,
        textColor: status.textColor,
        borderColor: AppColors.borderInk,
        borderWidth: isPressable ? 1.5 : 1.2,
      );
    } else {
      final borderColor = AppColors.borderInk;
      final borderWidth = isPressable ? 1.5 : 1.2;
      chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: status.bgColor,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: isPressable
              ? const [
                  BoxShadow(
                    color: AppColors.shadowWarm,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          status.label,
          style: AppTypography.kalam(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: status.textColor,
          ),
        ),
      );
    }

    if (isPressable && onTap != null) {
      chip = Semantics(
        button: true,
        child: GestureDetector(onTap: onTap, child: chip),
      );
    } else {
      chip = Semantics(container: true, child: chip);
    }
    return chip;
  }
}
