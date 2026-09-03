import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'neo_card.dart';

/// Centralized Soft-Brutalism Expandable Card (Accordion)
class NeoExpandableCard extends StatefulWidget {
  const NeoExpandableCard({
    super.key,
    required this.header,
    required this.expandedChild,
    this.isExpanded,
    this.onExpansionChanged,
    this.padding = AppSpacing.cardPadding,
    this.color = AppColors.bgSurface,
    this.borderRadius = AppRadius.card,
  });

  final Widget header;
  final Widget expandedChild;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadius borderRadius;

  @override
  State<NeoExpandableCard> createState() => _NeoExpandableCardState();
}

class _NeoExpandableCardState extends State<NeoExpandableCard> {
  bool _internalExpanded = false;

  bool get _effectiveExpanded => widget.isExpanded ?? _internalExpanded;

  void _toggle() {
    final next = !_effectiveExpanded;
    if (widget.isExpanded == null) {
      setState(() => _internalExpanded = next);
    }
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _effectiveExpanded;
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return NeoCard(
      color: widget.color,
      borderRadius: widget.borderRadius,
      padding: EdgeInsets.zero,
      onTap: _toggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: widget.padding,
            child: Row(
              children: [
                Expanded(child: widget.header),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: Duration(milliseconds: disableAnim ? 0 : 180),
                  curve: Curves.easeOut,
                  child: Icon(
                    AppIcons.caretDown,
                    size: 18,
                    color: AppColors.ink900,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderHairline,
                ),
                Padding(
                  padding: widget.padding,
                  child: widget.expandedChild,
                ),
              ],
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Duration(milliseconds: disableAnim ? 0 : 180),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}
