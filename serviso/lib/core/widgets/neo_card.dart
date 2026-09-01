import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A centralized Neo-Brutalist card container with solid 1.5px border
/// and optional tactile hard-shadow.
class NeoCard extends StatefulWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color = AppColors.bgSurface,
    this.borderColor = AppColors.borderInk,
    this.borderWidth = 1.5,
    this.borderRadius = AppRadius.card,
    this.showHardShadow = true,
    this.shadowOffset = const Offset(4, 4),  // DS v2: hard 4px 4px offset
    this.shadowColor = AppColors.borderInk,
    this.showSoftShadow = true,              // DS v2: soft diffuse layer
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final bool showHardShadow;
  final Offset shadowOffset;
  final Color shadowColor;
  final bool showSoftShadow;
  final VoidCallback? onTap;

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final currentOffset = widget.showHardShadow
        ? (_isPressed ? Offset.zero : widget.shadowOffset)
        : Offset.zero;
    final translateY = widget.onTap != null && _isPressed ? 2.0 : 0.0;

    // DS v2: --shadow-card: 0 8px 24px rgba(17,17,17,0.06), 4px 4px 0 #111
    final List<BoxShadow> shadows = [
      if (widget.showSoftShadow && !_isPressed)
        const BoxShadow(
          color: Color(0x0F111111), // rgba(17,17,17,0.06)
          offset: Offset(0, 8),
          blurRadius: 24,
          spreadRadius: 0,
        ),
      if (widget.showHardShadow)
        BoxShadow(
          color: widget.shadowColor,
          offset: currentOffset,
          blurRadius: 0,
          spreadRadius: 0,
        ),
    ];

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.translationValues(0, translateY, 0),
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      container = Semantics(
        button: true,
        enabled: true,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: container,
        ),
      );
    }

    return container;
  }
}
