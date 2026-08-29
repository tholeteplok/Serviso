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

/// A tactile Neo-Brutalist button with solid 1.5px black border,
/// pastel/dark fill, and solid black hard pop shadow.
/// Sesuai referensi gambar *Order Tracker* dan *Stay Healthy*.
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
    Color fg;

    switch (widget.variant) {
      case ThickButtonVariant.primary:
        bg = isEnabled ? AppColors.accentPrimary : AppColors.borderSubtle;
        fg = Colors.white;
        break;
      case ThickButtonVariant.secondary:
        bg = isEnabled ? AppColors.bgSurface : AppColors.borderSubtle;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.warning:
        bg = isEnabled ? AppColors.pastelYellow : AppColors.borderSubtle;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.danger:
        bg = isEnabled ? AppColors.pastelPink : AppColors.borderSubtle;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.info:
        bg = isEnabled ? AppColors.pastelBlue : AppColors.borderSubtle;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.mint:
        bg = isEnabled ? AppColors.pastelMint : AppColors.borderSubtle;
        fg = AppColors.ink900;
        break;
    }

    final double shadowDistance = isEnabled && !_isPressed ? 3.5 : 1.0;
    final double translateY = isEnabled && _isPressed ? 2.5 : 0.0;
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
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, translateY, 0),
        width: widget.isFullWidth ? double.infinity : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(
            color: AppColors.borderStrong,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.borderStrong,
              offset: Offset(0, shadowDistance),
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
