import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Centralized tactile Neo-Brutalist Progress Bar with Pill Border and Leading Thumb Dot.
/// Aligned with Serviso Soft Brutalism specifications.
class NeoProgressBar extends StatelessWidget {
  const NeoProgressBar({
    super.key,
    required this.value,
    this.height = 12.0,
    this.dotSize = 16.0,
    this.backgroundColor = AppColors.bgSurface,
    this.progressColor = AppColors.accentPrimary,
    this.borderColor = AppColors.borderInk,
    this.dotColor,
    this.showDot = true,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// Progress value between 0.0 and 1.0.
  final double value;

  /// Height of the progress track.
  final double height;

  /// Diameter of the leading thumb dot.
  final double dotSize;

  /// Track background color.
  final Color backgroundColor;

  /// Progress fill color.
  final Color progressColor;

  /// Border color for track and dot.
  final Color borderColor;

  /// Fill color of the leading thumb dot. Defaults to [progressColor].
  final Color? dotColor;

  /// Whether to display the tactile thumb dot at the progress tip.
  final bool showDot;

  /// Whether the progress bar is in an indeterminate loading state.
  final bool isLoading;

  /// Duration of the value transition animation.
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final effectiveDotColor = dotColor ?? progressColor;

    return SizedBox(
      height: showDot ? dotSize : height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          if (isLoading) {
            return _buildIndeterminateBar();
          }

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: clampedValue),
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              final fillWidth = totalWidth * animatedValue;
              // Ensure the dot stays within track boundaries
              final dotLeft = (fillWidth - (dotSize / 2)).clamp(0.0, totalWidth - dotSize);

              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  // Track background & border
                  Container(
                    width: totalWidth,
                    height: height,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                  ),

                  // Progress Fill
                  if (fillWidth > 0)
                    Container(
                      width: fillWidth,
                      height: height,
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: AppRadius.pill,
                      ),
                    ),

                  // Leading Thumb Dot
                  if (showDot && animatedValue > 0)
                    Positioned(
                      left: dotLeft,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: effectiveDotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.borderInk,
                              offset: Offset(1, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIndeterminateBar() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pill,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: const ClipRRect(
        borderRadius: AppRadius.pill,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          color: AppColors.accentPrimary,
        ),
      ),
    );
  }
}
