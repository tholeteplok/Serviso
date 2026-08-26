import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class InventoriScreen extends StatelessWidget {
  const InventoriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Scaffold(
      appBar: AppBar(title: const Text('Inventori')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.inkMuted),
            const SizedBox(height: 12),
            Text('Inventori', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Modul belum tersedia pada versi ini.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
