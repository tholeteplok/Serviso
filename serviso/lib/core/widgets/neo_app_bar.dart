import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Centralized Soft-Brutalism App Bar (Seamless Pilihan 2)
/// - Background: Canvas seamless [AppColors.bgBase]
/// - Title: Chakra Petch bold 20sp [AppColors.ink900]
/// - Leading: Tactile pop-back button with 1.5px ink border
/// - Actions: Unified spacing and tactile icon support
class NeoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NeoAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.showBack,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.onBack,
    this.toolbarHeight = 56.0,
  }) : assert(title != null || titleWidget != null, 'Either title or titleWidget must be provided');

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final bool? showBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final VoidCallback? onBack;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final bool effectiveShowBack = showBack ?? canPop;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && effectiveShowBack) {
      effectiveLeading = Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Center(
          child: Semantics(
            button: true,
            label: 'Kembali',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack ?? () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                borderRadius: AppRadius.pill,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderInk,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderInk,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    AppIcons.back,
                    size: 18,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null && title != null) {
      effectiveTitle = Text(
        title!,
        style: AppTypography.chakra(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink900,
        ),
      );
    }

    return AppBar(
      backgroundColor: AppColors.bgBase,
      foregroundColor: AppColors.ink900,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: effectiveLeading,
      leadingWidth: effectiveLeading != null ? 54 : null,
      title: effectiveTitle,
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: 8),
            ]
          : null,
      bottom: bottom,
    );
  }
}
