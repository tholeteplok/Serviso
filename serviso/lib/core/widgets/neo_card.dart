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
    this.borderColor = AppColors.borderStrong,
    this.borderWidth = 1.5,
    this.borderRadius = AppRadius.card,
    this.showHardShadow = false,
    this.shadowOffset = const Offset(3, 3),
    this.shadowColor = AppColors.shadowHard,
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

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
        boxShadow: widget.showHardShadow
            ? [
                BoxShadow(
                  color: widget.shadowColor,
                  offset: currentOffset,
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      container = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: container,
      );
    }

    return container;
  }
}
