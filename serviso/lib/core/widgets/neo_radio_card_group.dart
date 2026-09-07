import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Item model for [NeoRadioCardGroup].
class NeoRadioOption<T> {
  const NeoRadioOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.badge,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? badge;
}

/// Centralized Neo-Brutalist Radio Selection Card Group.
/// Designed for high-clarity choices (business models, modes, payment options)
/// with zero truncation, rich subtitles, and tactile tap targets.
class NeoRadioCardGroup<T> extends StatelessWidget {
  const NeoRadioCardGroup({
    super.key,
    required this.selectedValue,
    required this.onValueChanged,
    required this.options,
    this.activeCardColor = AppColors.pastelMint,
    this.activeBorderColor = AppColors.borderInk,
    this.inactiveCardColor = AppColors.bgSurface,
    this.inactiveBorderColor = AppColors.borderStrong,
    this.spacing = 8.0,
  });

  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final List<NeoRadioOption<T>> options;
  final Color activeCardColor;
  final Color activeBorderColor;
  final Color inactiveCardColor;
  final Color inactiveBorderColor;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          _buildOptionCard(options[i]),
          if (i < options.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }

  Widget _buildOptionCard(NeoRadioOption<T> option) {
    final isSelected = option.value == selectedValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onValueChanged(option.value),
        borderRadius: AppRadius.input,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeCardColor : inactiveCardColor,
            borderRadius: AppRadius.input,
            border: Border.all(
              color: isSelected ? activeBorderColor : inactiveBorderColor,
              width: isSelected ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom Tactile Radio Circle
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.borderInk,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.ink900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              if (option.icon != null) ...[
                option.icon!,
                const SizedBox(width: 10),
              ],

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.title,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.ink900,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        option.subtitle!,
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (option.badge != null) ...[
                const SizedBox(width: 8),
                option.badge!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
