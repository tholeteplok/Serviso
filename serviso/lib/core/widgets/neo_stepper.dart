import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum NeoStepperSize {
  compact,  // Height 36px, width ~104px, icon 14px, font 13px (in-card / retail)
  standard, // Height 44px, width ~136px, icon 18px, font 15px (forms / detail)
}

/// Tactile Pop-Brutalist Stepper counter based on the 3-segment pill capsule design.
/// Features a solid 1.5px black border, pop shadow, and a distinct pastel center
/// displaying the quantity between decrement and increment buttons.
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
    this.size = NeoStepperSize.standard,
    this.fixedWidth,
    this.isFullWidth = false,
    this.centerColor = AppColors.pastelMint,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final num min;
  final num max;
  final num step;
  final String? unit;
  final bool allowDecimals;
  final NeoStepperSize size;
  final double? fixedWidth;
  final bool isFullWidth;
  final Color centerColor;

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

    final double targetHeight;
    final double buttonWidth;
    final double iconSize;
    final double fontSize;
    final double defaultWidth;

    switch (size) {
      case NeoStepperSize.compact:
        targetHeight = 36.0;
        buttonWidth = 32.0;
        iconSize = 14.0;
        fontSize = 13.0;
        defaultWidth = 104.0;
        break;
      case NeoStepperSize.standard:
        targetHeight = 44.0;
        buttonWidth = 38.0;
        iconSize = 18.0;
        fontSize = 15.0;
        defaultWidth = 140.0;
        break;
    }

    final double resolvedWidth =
        isFullWidth ? double.infinity : (fixedWidth ?? defaultWidth);

    return Container(
      width: resolvedWidth,
      height: targetHeight,
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
            offset: Offset(2, 2),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Decrement Button [-]
          Semantics(
            button: true,
            enabled: canDecrement,
            label: 'Kurangi',
            child: SizedBox(
              width: buttonWidth,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canDecrement ? _decrement : null,
                  child: Center(
                    child: Icon(
                      AppIcons.minus,
                      size: iconSize,
                      color: canDecrement
                          ? AppColors.ink900
                          : AppColors.borderSubtle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Center Quantity Box [value (unit)] with pastelMint background
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: centerColor,
                border: const Border(
                  left: BorderSide(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                  right: BorderSide(
                    color: AppColors.borderStrong,
                    width: 1.5,
                  ),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayValue,
                      style: AppTypography.mono(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                      maxLines: 1,
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 3),
                      Text(
                        unit!,
                        style: AppTypography.inter(
                          fontSize: fontSize - 2,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Increment Button [+]
          Semantics(
            button: true,
            enabled: canIncrement,
            label: 'Tambah',
            child: SizedBox(
              width: buttonWidth,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canIncrement ? _increment : null,
                  child: Center(
                    child: Icon(
                      AppIcons.add,
                      size: iconSize,
                      color: canIncrement
                          ? AppColors.ink900
                          : AppColors.borderSubtle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
