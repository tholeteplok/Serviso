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

/// Docked Bottom Navigation Bar (Non-Pill, Edge-to-Edge) with Pastel Pop-Brutalism styling
/// aligned with reference image (center circular [+] action button, active tab with pastel purple dot).
class PastelPopBottomBar extends StatelessWidget {
  const PastelPopBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onCenterActionTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PastelPopBottomBarItem> items;
  final VoidCallback? onCenterActionTap;

  @override
  Widget build(BuildContext context) {
    final leftItems = items.take(2).toList();
    final rightItems = items.skip(2).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.borderInk, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < leftItems.length; i++)
                _buildTabItem(index: i, item: leftItems[i]),
              _buildCenterButton(),
              for (int i = 0; i < rightItems.length; i++)
                _buildTabItem(index: i + 2, item: rightItems[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required PastelPopBottomBarItem item}) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected ? AppColors.ink900 : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pastelPurple,
                  border: Border.all(color: AppColors.borderInk, width: 1.0),
                ),
              )
            else
              const SizedBox(width: 6, height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return InkWell(
      onTap: onCenterActionTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accentPrimary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderInk, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add,
          color: AppColors.ink900,
          size: 24,
        ),
      ),
    );
  }
}
