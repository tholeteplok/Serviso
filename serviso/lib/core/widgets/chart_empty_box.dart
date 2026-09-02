import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Centralized empty state container for charts per DS v2 spec:
/// 1.5px dashed ink border, warm cream (#FFFBF7) background, rounded 12px.
class ChartEmptyBox extends StatelessWidget {
  const ChartEmptyBox({
    super.key,
    this.title = 'Belum ada data periode ini',
    this.message = 'Pilih rentang lain atau catat transaksi dulu.',
    this.height = 180,
  });

  final String title;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderInk,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.borderInk,
                width: 1.5,
              ),
            ),
            child: Icon(
              PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
              size: 18,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.chakra(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme().bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}