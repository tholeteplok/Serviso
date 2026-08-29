import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tactile Toggle Switch styled after the Contra Pop-Brutalism Design Kit.
/// Pill track with solid 1.5px black border and animated black knob.
class NeoSwitch extends StatelessWidget {
  const NeoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.pastelYellow,
    this.inactiveColor = Colors.white,
    this.width = 54.0,
    this.height = 28.0,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final knobSize = height - 8;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: AppColors.borderStrong,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.borderStrong,
              offset: Offset(0, 1.5),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knobSize,
            height: knobSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ink900,
            ),
          ),
        ),
      ),
    );
  }
}
