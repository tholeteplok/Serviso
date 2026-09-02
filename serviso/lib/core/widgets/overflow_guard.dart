import 'package:flutter/material.dart';

/// DS v2 overflow guard — mirror CSS: html,body{max-width:100%; overflow-x:clip}
/// + .wrap max-width + img max-width + 360px bengkel guard.
class OverflowGuard extends StatelessWidget {
  const OverflowGuard({super.key, required this.child, this.maxWidth = 1200});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      return ClipRect(
        clipBehavior: Clip.hardEdge,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0, maxWidth: double.infinity),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 0),
              child: child,
            ),
          ),
        ),
      );
    });
  }
}

/// Horizontal scroll with clip guard for kanban-like boards.
class GuardedHorizontalScroll extends StatelessWidget {
  const GuardedHorizontalScroll({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0),
          child: child,
        ),
      ),
    );
  }
}
