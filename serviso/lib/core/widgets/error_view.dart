import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'thick_bottom_border_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Gagal memuat data',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.pastelCream,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.borderInk, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.borderInk,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pastelPink,
                  borderRadius: AppRadius.button,
                  border: Border.all(color: AppColors.borderInk, width: 1.5),
                ),
                child: Icon(
                  AppIcons.alertCircle,
                  size: 22,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ThickBottomBorderButton(
                variant: ThickButtonVariant.danger,
                onPressed: onRetry,
                icon: Icon(AppIcons.refresh, size: 16),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
