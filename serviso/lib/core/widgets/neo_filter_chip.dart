import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Tactile Pop-Brutalist Filter Chip with stadium capsule pill shape,
/// solid 1.5px border, and pop shadow when selected.
class NeoFilterChip extends StatelessWidget {
  const NeoFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = AppColors.pastelMint,
    this.inactiveColor = AppColors.canvas,
    this.icon,
    this.count,
    this.height = 36.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;
  final Widget? icon;
  final int? count;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : inactiveColor,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: AppColors.borderInk,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: AppColors.borderInk,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.ink900,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.ink900 : AppColors.borderHairline,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      count.toString(),
                      style: AppTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.bgSurface : AppColors.ink900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
