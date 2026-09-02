import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadow.dart';
import '../theme/app_spacing.dart';

enum NeoCardVariant { pressable, info }

/// DS v2 Warm Industrial — Card
/// pressable: 1.5 ink + hard 4px + lift 1px + cursor pointer
/// info: 1px hairline #E8E0D6 flat soft only — no lift
class NeoCard extends StatefulWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color = AppColors.bgSurface,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = AppRadius.card,
    this.showHardShadow,
    this.shadowOffset = const Offset(4, 4),
    this.shadowColor = AppColors.borderInk,
    this.showSoftShadow,
    this.onTap,
    this.variant,
  });

  const NeoCard.pressable({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color = AppColors.bgSurface,
    this.borderRadius = AppRadius.card,
    this.onTap,
  })  : borderColor = AppColors.borderInk,
        borderWidth = 1.5,
        showHardShadow = true,
        shadowOffset = const Offset(4, 4),
        shadowColor = AppColors.borderInk,
        showSoftShadow = true,
        variant = NeoCardVariant.pressable;

  const NeoCard.info({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color = AppColors.bgSurface,
    this.borderRadius = AppRadius.card,
  })  : borderColor = AppColors.borderHairline,
        borderWidth = 1.0,
        showHardShadow = false,
        shadowOffset = Offset.zero,
        shadowColor = AppColors.borderInk,
        showSoftShadow = true,
        variant = NeoCardVariant.info,
        onTap = null;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius borderRadius;
  final bool? showHardShadow;
  final Offset shadowOffset;
  final Color shadowColor;
  final bool? showSoftShadow;
  final VoidCallback? onTap;
  final NeoCardVariant? variant;

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // Resolve variant defaults
    final isInfo = widget.variant == NeoCardVariant.info;
    final hasTap = widget.onTap != null && !isInfo;
    final effBorderColor = widget.borderColor ?? (isInfo ? AppColors.borderHairline : AppColors.borderInk);
    final effBorderWidth = widget.borderWidth ?? (isInfo ? 1.0 : 1.5);
    final effShowHard = widget.showHardShadow ?? !isInfo;
    final effShowSoft = widget.showSoftShadow ?? true;

    final currentOffset = effShowHard
        ? (_isPressed ? Offset.zero : widget.shadowOffset)
        : Offset.zero;
    // Info never lifts
    final translateY = hasTap && _isPressed ? 1.0 : 0.0;

    final List<BoxShadow> shadows = [
      if (effShowSoft && !_isPressed) AppShadow.cardSoft,
      if (effShowHard)
        BoxShadow(
          color: widget.shadowColor,
          offset: currentOffset,
          blurRadius: 0,
        ),
    ];

    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Widget container = AnimatedContainer(
      duration: Duration(milliseconds: disableAnim ? 0 : 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(translateY, translateY, 0),
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: effBorderColor,
          width: effBorderWidth,
        ),
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: widget.child,
    );

    if (hasTap) {
      container = Semantics(
        button: true,
        enabled: true,
        child: Focus(
          canRequestFocus: true,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: Container(
            decoration: _isFocused
                ? BoxDecoration(
                    borderRadius: widget.borderRadius,
                    boxShadow: const [BoxShadow(color: Color(0xFFFFC526), blurRadius: 0, spreadRadius: 2)],
                  )
                : null,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: container,
            ),
          ),
        ),
      );
    } else if (isInfo) {
      container = Semantics(container: true, child: container);
    }

    return container;
  }
}
