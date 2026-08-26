import 'package:flutter/material.dart';

import '../models/wo_status.dart';
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTypography.textTheme().labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: status.accentColor,
            ),
      ),
    );
  }
}
