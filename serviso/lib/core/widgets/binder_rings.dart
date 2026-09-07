import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Decorative binder eyelet rings mimicking mechanical workshop clipboards
/// and perforated punch holes at the top of active Work Order / receipt cards.
class BinderRings extends StatelessWidget {
  const BinderRings({
    super.key,
    this.count = 3,
    this.ringSize = 12.0,
    this.spacing = 10.0,
    this.outerColor = AppColors.pastelYellow,
    this.innerColor = AppColors.bgBase,
    this.borderColor = AppColors.borderInk,
  });

  final int count;
  final double ringSize;
  final double spacing;
  final Color outerColor;
  final Color innerColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              color: outerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowWarm,
                  offset: Offset(1.0, 1.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: ringSize * 0.45,
                height: ringSize * 0.45,
                decoration: BoxDecoration(
                  color: innerColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
