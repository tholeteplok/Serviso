import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'thick_bottom_border_button.dart';

enum NeoButtonVariant {
  primary,
  secondary,
  danger,
}

/// Compatibility wrapper around [ThickBottomBorderButton].
class NeoButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ThickButtonVariant mapped = switch (variant) {
      NeoButtonVariant.primary => ThickButtonVariant.primary,
      NeoButtonVariant.secondary => ThickButtonVariant.secondary,
      NeoButtonVariant.danger => ThickButtonVariant.danger,
    };

    return ThickBottomBorderButton(
      onPressed: onPressed,
      variant: mapped,
      icon: icon,
      isFullWidth: isFullWidth,
      padding: padding,
      isLoading: isLoading,
      child: child,
    );
  }
}
