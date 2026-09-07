import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadow.dart';
import '../theme/app_spacing.dart';

enum NeoCardVariant { pressable, info }

/// DS v2 Warm Industrial / Soft Brutalism — Card
/// pressable: 1.5 ink + hard 4px + lift 1px + cursor pointer
/// info: 1.5 ink + 0px shadow (flat grounded) + 20px radius
class NeoCard extends StatefulWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.header,
    this.headerColor,
    this.headerPadding,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color = AppColors.bgSurface,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = AppRadius.card,
    this.showHardShadow,
    this.shadowOffset = const Offset(3, 3),
    this.shadowColor = AppColors.shadowWarm,
    this.showSoftShadow,
    this.onTap,
    this.variant,
  });

  const NeoCard.pressable({
    super.key,
    required this.child,
    this.header,
    this.headerColor,
    this.headerPadding,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color = AppColors.bgSurface,
    this.borderRadius = AppRadius.card,
    this.onTap,
  })  : borderColor = AppColors.borderInk,
        borderWidth = 1.5,
        showHardShadow = true,
        shadowOffset = const Offset(3, 3),
        shadowColor = AppColors.shadowWarm,
        showSoftShadow = false,
        variant = NeoCardVariant.pressable;

  const NeoCard.info({
    super.key,
    required this.child,
    this.header,
    this.headerColor,
    this.headerPadding,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color = AppColors.bgSurface,
    this.borderColor = AppColors.borderInk,
    this.borderWidth = 1.2,
    this.borderRadius = AppRadius.card,
  })  : showHardShadow = false,
        shadowOffset = Offset.zero,
        shadowColor = AppColors.shadowWarm,
        showSoftShadow = false,
        variant = NeoCardVariant.info,
        onTap = null;

  final Widget child;
  final Widget? header;
  final Color? headerColor;
  final EdgeInsetsGeometry? headerPadding;
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
    final effBorderColor = widget.borderColor ?? AppColors.borderInk;
    final effBorderWidth = widget.borderWidth ?? 1.5;
    final effShowHard = widget.showHardShadow ?? (hasTap && !isInfo);
    final effShowSoft = widget.showSoftShadow ?? false;

    final currentOffset = effShowHard
        ? (_isPressed ? const Offset(1.0, 1.0) : widget.shadowOffset)
        : Offset.zero;
    // Info never lifts
    final translateY = hasTap && _isPressed ? 2.0 : 0.0;

    final List<BoxShadow> shadows = [
      if (effShowSoft && !_isPressed) AppShadow.cardSoft,
      if (effShowHard)
        BoxShadow(
          color: widget.shadowColor,
          offset: currentOffset,
          blurRadius: 0,
        ),
    ];

    final innerContent = widget.header != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: widget.headerPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.headerColor ?? AppColors.pastelYellow,
                  border: Border(
                    bottom: BorderSide(
                      color: effBorderColor,
                      width: 1.2,
                    ),
                  ),
                ),
                child: widget.header!,
              ),
              Container(
                color: widget.color,
                padding: widget.padding,
                child: widget.child,
              ),
            ],
          )
        : Padding(
            padding: widget.padding,
            child: widget.child,
          );

    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Widget container = AnimatedContainer(
      duration: Duration(milliseconds: disableAnim ? 0 : 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(translateY, translateY, 0),
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: effBorderColor,
          width: effBorderWidth,
        ),
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: innerContent,
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
