import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

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

/// Docked Bottom Navigation Bar with Pastel Pop-Brutalism styling.
/// - Tab items: Vertical layout with icon on top and label below.
/// - Center Action Button: Circular [+] action button shifted up to overlap the top navbar border by 50%.
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

  static const double _buttonDiameter = 54.0;
  static const double _overlapOffset = -27.0; // 50% of button diameter

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
          height: 66,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < leftItems.length; i++)
                Expanded(
                  child: _buildTabItem(index: i, item: leftItems[i]),
                ),
              SizedBox(
                width: 60,
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, _overlapOffset),
                    child: _buildCenterButton(),
                  ),
                ),
              ),
              for (int i = 0; i < rightItems.length; i++)
                Expanded(
                  child: _buildTabItem(index: i + 2, item: rightItems[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required PastelPopBottomBarItem item}) {
    final isSelected = index == currentIndex;

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: AppRadius.button,
        splashColor: AppColors.accentPrimary.withValues(alpha: 0.2),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentPrimary : Colors.transparent,
                  borderRadius: AppRadius.pill,
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.accentPrimary : AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Semantics(
      button: true,
      label: 'Buat SPK / Transaksi Baru',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onCenterActionTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: _buttonDiameter,
            height: _buttonDiameter,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderInk, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.ink900,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              AppIcons.add,
              color: AppColors.onPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
