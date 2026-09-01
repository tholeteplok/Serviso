import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Style configuration for the binder wire rings connecting cards.
enum BinderRingAlignment {
  /// Two rings positioned symmetrically towards the left and right.
  twoSides,

  /// A single ring positioned at the horizontal center.
  center,
}

/// A tactile binder ring / wire connector widget drawn between consecutive cards.
class BinderRingConnector extends StatelessWidget {
  const BinderRingConnector({
    super.key,
    this.height = 18.0,
    this.width = 10.0,
    this.strokeWidth = 1.5,
    this.color = AppColors.borderInk,
    this.fillColor = const Color(0xFFEFEFEF),
  });

  final double height;
  final double width;
  final double strokeWidth;
  final Color color;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + 8,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top hole
          Positioned(
            top: 0,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
          // Bottom hole
          Positioned(
            bottom: 0,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
          // Metallic wire link
          Positioned.fill(
            top: 2,
            bottom: 2,
            child: Center(
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(width / 2),
                  border: Border.all(
                    color: color,
                    width: strokeWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Container that arranges a sequence of cards vertically, linking them
/// with physical binder wire rings (as seen in the reference design).
class LinkedCardGroup extends StatelessWidget {
  const LinkedCardGroup({
    super.key,
    required this.children,
    this.ringAlignment = BinderRingAlignment.twoSides,
    this.ringHeight = 16.0,
    this.ringOffset = 48.0,
  });

  final List<Widget> children;
  final BinderRingAlignment ringAlignment;
  final double ringHeight;
  final double ringOffset;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    final items = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);

      if (i < children.length - 1) {
        // Connector row between cards
        items.add(
          SizedBox(
            height: ringHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                switch (ringAlignment) {
                  case BinderRingAlignment.center:
                    return Center(
                      child: BinderRingConnector(height: ringHeight),
                    );
                  case BinderRingAlignment.twoSides:
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: ringOffset),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BinderRingConnector(height: ringHeight),
                          BinderRingConnector(height: ringHeight),
                        ],
                      ),
                    );
                }
              },
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }
}

/// A centralized card widget following the Soft Pastel UI + Line-Art Outline style.
///
/// Features:
/// - Universal black border outline ([AppColors.borderInk])
/// - Large friendly rounded corners ([AppRadius.card])
/// - Optional header with pastel background tint
/// - Optional tactile progress capsule with black outline
/// - Optional tactile press response
class LinkedCard extends StatefulWidget {
  const LinkedCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.headerColor,
    this.backgroundColor = AppColors.bgSurface,
    this.borderColor = AppColors.borderInk,
    this.borderWidth = 1.5,
    this.borderRadius = AppRadius.card,
    this.padding = AppSpacing.cardPadding,
    this.progress,
    this.progressColor = AppColors.statusProgress,
    this.progressLabel,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? headerColor;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// Progress value between 0.0 and 1.0 (optional)
  final double? progress;

  /// Color of the filled progress segment
  final Color progressColor;

  /// Optional label displayed on top of or beside the progress bar
  final String? progressLabel;

  final VoidCallback? onTap;

  @override
  State<LinkedCard> createState() => _LinkedCardState();
}

class _LinkedCardState extends State<LinkedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasHeader = widget.title != null || widget.leading != null || widget.trailing != null;
    final hasProgress = widget.progress != null;
    final translateY = widget.onTap != null && _isPressed ? 2.0 : 0.0;

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.headerColor ?? Colors.transparent,
              borderRadius: BorderRadius.vertical(
                top: widget.borderRadius.topLeft,
              ),
              border: Border(
                bottom: BorderSide(
                  color: widget.borderColor,
                  width: widget.borderWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: AppTypography.inter(
                            color: AppColors.ink900,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: AppTypography.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ],
        if (hasProgress) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.progressLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      widget.progressLabel!,
                      style: AppTypography.inter(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: widget.borderColor,
                      width: widget.borderWidth,
                    ),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.progress!.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.progressColor,
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ],
    );

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.translationValues(0, translateY, 0),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: cardContent,
      ),
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
