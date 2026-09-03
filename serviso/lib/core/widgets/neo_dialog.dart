import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadow.dart';
import '../theme/app_typography.dart';
import 'thick_bottom_border_button.dart';

/// Centralized Neo-Brutalist Dialog Container (DS v2 L2 Hybrid Shadow)
class NeoDialog extends StatelessWidget {
  const NeoDialog({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth = 420,
  });

  /// Standardized alert dialog structure with Chakra Petch title, content, and action buttons
  NeoDialog.alert({
    super.key,
    required String title,
    required Widget content,
    List<Widget>? actions,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth = 420,
  }) : child = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.chakra(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(child: content),
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        );

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.modal,
            border: Border.all(
              color: AppColors.borderInk,
              width: 1.5,
            ),
            boxShadow: AppShadow.l2,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Opens a centralized NeoDialog
Future<T?> showNeoDialog<T>({
  required BuildContext context,
  Widget? child,
  WidgetBuilder? builder,
  bool barrierDismissible = true,
}) {
  assert(child != null || builder != null, 'Either child or builder must be provided');
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: const Color(0x73111111), // 45% ink900 scrim
    builder: (ctx) {
      final widget = builder != null ? builder(ctx) : child!;
      if (widget is NeoDialog) return widget;
      return NeoDialog(child: widget);
    },
  );
}

/// Opens a standardized confirmation dialog with tactile buttons and L2 hybrid shadow
Future<bool?> showNeoConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  bool isDanger = false,
  Widget? icon,
}) {
  return showNeoDialog<bool>(
    context: context,
    builder: (dialogCtx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDanger ? AppColors.pastelPink : AppColors.pastelYellow,
              borderRadius: AppRadius.button,
              border: Border.all(color: AppColors.borderInk, width: 1.5),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: AppTypography.chakra(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppTypography.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ThickBottomBorderButton(
              variant: ThickButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 10),
            ThickBottomBorderButton(
              variant: isDanger ? ThickButtonVariant.danger : ThickButtonVariant.primary,
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ],
    ),
  );
}
