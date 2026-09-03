import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Centralized Neo-Brutalist Bottom Sheet Container
class NeoBottomSheet extends StatelessWidget {
  const NeoBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.modalTop,
        border: Border(
          top: BorderSide(color: AppColors.borderInk, width: 1.5),
          left: BorderSide(color: AppColors.borderInk, width: 1.5),
          right: BorderSide(color: AppColors.borderInk, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tactile Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.borderHairline,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.borderInk, width: 1),
                  ),
                ),
              ),
              if (title != null || titleWidget != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: titleWidget ??
                      Text(
                        title!,
                        style: AppTypography.chakra(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                ),
                const SizedBox(height: 12),
              ],
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show a standardized NeoBottomSheet
Future<T?> showNeoBottomSheet<T>({
  required BuildContext context,
  Widget? child,
  WidgetBuilder? builder,
  String? title,
  Widget? titleWidget,
  bool isScrollControlled = true,
}) {
  assert(child != null || builder != null, 'Either child or builder must be provided');
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) {
      final content = builder != null ? builder(ctx) : child!;
      if (content is NeoBottomSheet) return content;
      return NeoBottomSheet(
        title: title,
        titleWidget: titleWidget,
        child: content,
      );
    },
  );
}
