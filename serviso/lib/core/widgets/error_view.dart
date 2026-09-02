import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8A0A0), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB5C1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderInk, width: 1.5),
                ),
                child: const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.ink900),
              ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: onRetry, child: const Text('Coba Lagi'))),
            ]),
          ],
          ),
        ),
      ),
    );
  }
}
