import 'package:flutter/material.dart';

import '../models/wo_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.isPressable = false, this.onTap});

  final WoStatus status;
  /// DS v2: isPressable false → info (1px hairline flat, no lift), true → 1.5 ink + hard + lift
  final bool isPressable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isPressable ? AppColors.borderInk : AppColors.borderHairline;
    final borderWidth = isPressable ? 1.5 : 1.0;
    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: isPressable
            ? const [
                BoxShadow(color: Color(0x1A111111), offset: Offset(0, 2), blurRadius: 10),
                BoxShadow(color: AppColors.borderInk, offset: Offset(2, 2), blurRadius: 0),
              ]
            : null,
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
