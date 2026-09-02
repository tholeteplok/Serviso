import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadow.dart';

/// DS v2 Pill Bar — for landscape tablet / PC (portrait = bottom dock).
/// Spec: docs/serviso-design-system-v2.html pill bar — clean white container,
/// active mint pill #3FBE85 + border ink 1.5, height 44 pill, soft+hard shadow.
class NeoPillBar extends StatelessWidget {
  const NeoPillBar({super.key, required this.items, required this.selectedIndex, required this.onSelected});

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderInk, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 4), blurRadius: 18), AppShadow.buttonHard],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (i) {
          final sel = i == selectedIndex;
          return Flexible(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: Duration(milliseconds: (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ? 0 : 160),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: sel ? Border.all(color: AppColors.borderInk, width: 1.5) : null,
                ),
                child: Text(items[i], style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.w600, color: sel ? AppColors.ink900 : AppColors.textSecondary)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Adaptive nav: portrait mobile = bottom dock, landscape/tablet = pill or sidebar.
class AdaptiveNav extends StatelessWidget {
  const AdaptiveNav({super.key, required this.items, required this.selectedIndex, required this.onSelected, required this.child});
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isPortraitMobile = w < 600 && MediaQuery.orientationOf(context) == Orientation.portrait;
    if (isPortraitMobile) return child;
    // landscape/tablet: show pill centered top
    return Column(children: [
      const SizedBox(height: 12),
      Center(child: NeoPillBar(items: items, selectedIndex: selectedIndex, onSelected: onSelected)),
      const SizedBox(height: 12),
      Expanded(child: child),
    ]);
  }
}
