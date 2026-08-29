import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PastelPopBottomBarItem {
  const PastelPopBottomBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating Pill Bottom Navigation Bar with Pastel Pop-Brutalism styling
/// based on the *Order Tracker* & *Stay Healthy* design references.
class PastelPopBottomBar extends StatelessWidget {
  const PastelPopBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PastelPopBottomBarItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12, top: 4),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.navBarBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.borderStrong,
                offset: Offset(0, 3.5),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: isSelected
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                      : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppColors.navBarActive,
                          borderRadius: BorderRadius.circular(20),
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
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: AppColors.ink900,
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppColors.ink900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
