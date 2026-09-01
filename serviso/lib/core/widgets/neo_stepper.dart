import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Tactile Pop-Brutalist Stepper counter based on the Contra Design Kit.
class NeoStepper extends StatelessWidget {
  const NeoStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = double.infinity,
    this.step = 1,
    this.unit,
    this.allowDecimals = false,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final num min;
  final num max;
  final num step;
  final String? unit;
  final bool allowDecimals;

  void _decrement() {
    final next = value - step;
    if (next >= min) {
      onChanged(next);
    }
  }

  void _increment() {
    final next = value + step;
    if (next <= max) {
      onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min;
    final canIncrement = value < max;

    final displayValue = allowDecimals
        ? value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)
        : value.toInt().toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.borderStrong,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderStrong,
            offset: Offset(0, 2),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement Button [-] — 40dp for a11y
          Semantics(
            button: true,
            enabled: canDecrement,
            label: 'Kurangi',
            child: InkWell(
              onTap: canDecrement ? _decrement : null,
              borderRadius: AppRadius.pill,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canDecrement ? AppColors.pastelYellow : AppColors.borderHairline,
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  AppIcons.minus,
                  size: 18,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: AppTypography.mono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Increment Button [+] — 40dp for a11y
          Semantics(
            button: true,
            enabled: canIncrement,
            label: 'Tambah',
            child: InkWell(
              onTap: canIncrement ? _increment : null,
              borderRadius: AppRadius.pill,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canIncrement ? AppColors.pastelYellow : AppColors.borderHairline,
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  AppIcons.add,
                  size: 18,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
