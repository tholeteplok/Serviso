import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum ThickButtonVariant {
  primary,
  secondary,
  warning,
  danger,
  info,
  mint,
}

/// A tactile button with a thick bottom-border (2.5–3x thicker than top/sides)
/// that simulates a 3D physical keypress without blurry drop shadows.
/// Based on docs/design (1).md §5 & §6.2.
class ThickBottomBorderButton extends StatefulWidget {
  const ThickBottomBorderButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ThickButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.padding = AppSpacing.buttonPadding,
    this.borderRadius,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ThickButtonVariant variant;
  final Widget? icon;
  final bool isFullWidth;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool isLoading;

  @override
  State<ThickBottomBorderButton> createState() => _ThickBottomBorderButtonState();
}

class _ThickBottomBorderButtonState extends State<ThickBottomBorderButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color bottomBorderColor;
    Color topSideBorderColor;
    Color fg;

    switch (widget.variant) {
      case ThickButtonVariant.primary:
        bg = isEnabled ? AppColors.accentPrimary : AppColors.borderHairline;
        bottomBorderColor = isEnabled ? AppColors.accentPrimaryBorder : AppColors.borderHairline;
        topSideBorderColor = isEnabled ? AppColors.accentPrimaryBorder : AppColors.borderHairline;
        fg = Colors.white;
        break;
      case ThickButtonVariant.secondary:
        bg = isEnabled ? const Color(0xFFF3F3F3) : AppColors.borderHairline;
        bottomBorderColor = isEnabled ? const Color(0xFFD8D0C7) : AppColors.borderHairline;
        topSideBorderColor = isEnabled ? const Color(0xFFE5E0DA) : AppColors.borderHairline;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.warning:
        bg = isEnabled ? AppColors.pastelYellow : AppColors.borderHairline;
        bottomBorderColor = isEnabled ? AppColors.statusWaitingBorder : AppColors.borderHairline;
        topSideBorderColor = isEnabled ? AppColors.statusWaitingBorder.withValues(alpha: 0.5) : AppColors.borderHairline;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.danger:
        bg = isEnabled ? AppColors.pastelPink : AppColors.borderHairline;
        bottomBorderColor = isEnabled ? AppColors.statusCancelledBorder : AppColors.borderHairline;
        topSideBorderColor = isEnabled ? AppColors.statusCancelledBorder.withValues(alpha: 0.5) : AppColors.borderHairline;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.info:
        bg = isEnabled ? AppColors.pastelBlue : AppColors.borderHairline;
        bottomBorderColor = isEnabled ? AppColors.statusProgressBorder : AppColors.borderHairline;
        topSideBorderColor = isEnabled ? AppColors.statusProgressBorder.withValues(alpha: 0.5) : AppColors.borderHairline;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.mint:
        bg = isEnabled ? AppColors.pastelMint : AppColors.borderHairline;
        bottomBorderColor = isEnabled ? AppColors.statusDoneBorder : AppColors.borderHairline;
        topSideBorderColor = isEnabled ? AppColors.statusDoneBorder.withValues(alpha: 0.5) : AppColors.borderHairline;
        fg = AppColors.ink900;
        break;
    }

    final double bottomWidth = isEnabled && !_isPressed ? 3.5 : 1.0;
    final double translateY = isEnabled && _isPressed ? 2.0 : 0.0;
    final radius = widget.borderRadius ?? (widget.isFullWidth ? AppRadius.card : AppRadius.pill);

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
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, translateY, 0),
        width: widget.isFullWidth ? double.infinity : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(
            color: topSideBorderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: bottomBorderColor,
              offset: Offset(0, bottomWidth),
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
