import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum NeoButtonVariant {
  primary,
  secondary,
  danger,
}

/// A tactile Neo-Brutalist button with solid 1.5px border,
/// bold contrast, and offset hard shadow that collapses on press.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = NeoButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.padding = AppSpacing.buttonPadding,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final NeoButtonVariant variant;
  final Widget? icon;
  final bool isFullWidth;
  final EdgeInsetsGeometry padding;
  final bool isLoading;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    switch (widget.variant) {
      case NeoButtonVariant.primary:
        bg = isEnabled ? AppColors.accentPrimary : AppColors.borderSubtle;
        fg = Colors.white;
        break;
      case NeoButtonVariant.secondary:
        bg = isEnabled ? AppColors.bgSurface : AppColors.borderSubtle;
        fg = AppColors.textPrimary;
        break;
      case NeoButtonVariant.danger:
        bg = isEnabled ? AppColors.statusCancelled : AppColors.borderSubtle;
        fg = Colors.white;
        break;
    }

    final shadowOffset = isEnabled && !_isPressed
        ? const Offset(2.5, 2.5)
        : Offset.zero;

    Widget content = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                child: widget.child,
              ),
            ],
          );

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: widget.isFullWidth ? double.infinity : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.button,
          border: Border.all(
            color: AppColors.borderStrong,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowHard,
              offset: shadowOffset,
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}
