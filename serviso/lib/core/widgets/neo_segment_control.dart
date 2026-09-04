import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadow.dart';
import '../theme/app_typography.dart';

class NeoSegmentItem<T> {
  const NeoSegmentItem({
    required this.value,
    required this.label,
    this.count,
    this.icon,
    this.badgeColor,
    this.activeColor,
  });

  final T value;
  final String label;
  final int? count;
  final Widget? icon;
  final Color? badgeColor;
  final Color? activeColor;
}

/// Tactile Pop-Brutalist Segment Control based on the Contra Design Kit (2 & 3 Menus).
/// Outer pill container with 1.5px black border and floating active pill.
class NeoSegmentControl<T> extends StatelessWidget {
  const NeoSegmentControl({
    super.key,
    required this.selectedValue,
    required this.onValueChanged,
    required this.items,
    this.activeColor = AppColors.accentPrimary,
    this.height = 46.0,
    this.containerColor = AppColors.bgSurface,
  });

  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final List<NeoSegmentItem<T>> items;
  final Color activeColor;
  final double height;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // DS v2 spec: container #F5F1EB
        color: const Color(0xFFF5F1EB),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.borderInk,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderInk,
            offset: Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          final currentActiveColor = item.activeColor ?? activeColor;
          final isDarkActive = isSelected &&
              ThemeData.estimateBrightnessForColor(currentActiveColor) == Brightness.dark;
          final textColor = isDarkActive ? Colors.white : AppColors.ink900;

          return Expanded(
            child: GestureDetector(
              onTap: () => onValueChanged(item.value),
              child: AnimatedContainer(
                duration: Duration(milliseconds: (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ? 0 : 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? currentActiveColor : Colors.transparent,
                  borderRadius: AppRadius.pill,
                  border: isSelected
                      ? Border.all(color: AppColors.borderInk, width: 1.5)
                      : null,
                  boxShadow: isSelected
                      ? const [AppShadow.buttonHard]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.badgeColor != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.badgeColor,
                          border: Border.all(
                            color: AppColors.borderStrong,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else if (item.icon != null) ...[
                      IconTheme.merge(
                        data: IconThemeData(color: textColor),
                        child: item.icon!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          color: textColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (item.count != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${item.count})',
                        style: AppTypography.inter(
                          color: textColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
