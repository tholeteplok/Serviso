import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum ThickButtonVariant {
  primary,
  secondary,
  warning,
  danger,
  info,
  mint,
  amber,  // DS v2: solid #FFC526 for secondary CTAs
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
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;

    switch (widget.variant) {
      case ThickButtonVariant.primary:
        bg = AppColors.accentPrimary;
        fg = AppColors.onPrimary;
        break;
      case ThickButtonVariant.secondary:
        bg = AppColors.bgSurface;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.warning:
        bg = AppColors.pastelYellow;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.danger:
        bg = AppColors.pastelPink;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.info:
        bg = AppColors.pastelPurple;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.mint:
        bg = AppColors.pastelMint;
        fg = AppColors.ink900;
        break;
      case ThickButtonVariant.amber:
        bg = isEnabled ? AppColors.amber : AppColors.borderSubtle;
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
        : IconTheme.merge(
            data: IconThemeData(color: fg),
            child: Row(
              mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: AppTypography.inter(
                    color: fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          );

    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Widget btn = AnimatedContainer(
      duration: Duration(milliseconds: disableAnim ? 0 : 70),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(translateY, translateY, 0),
      width: widget.isFullWidth ? double.infinity : null,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.borderInk,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderInk,
            offset: Offset(shadowDistance, shadowDistance),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: content,
    );

    // Disabled: opacity 0.45 per spec — wrap, not color swap
    if (!isEnabled) {
      btn = Opacity(opacity: 0.45, child: IgnorePointer(ignoring: !widget.isLoading, child: btn));
    }
    // Focus ring amber 2px offset 2 + 44px min constraint
    btn = Semantics(
      button: true,
      enabled: isEnabled,
      child: Focus(
        canRequestFocus: isEnabled,
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: Container(
          decoration: _isFocused
              ? BoxDecoration(
                  borderRadius: radius,
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFFFC526), blurRadius: 0, spreadRadius: 2),
                  ],
                )
              : null,
          child: GestureDetector(
            onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
            onTap: isEnabled ? widget.onPressed : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 44, minWidth: widget.isFullWidth ? 0 : 44),
              child: btn,
            ),
          ),
        ),
      ),
    );
    return btn;
  }
}
