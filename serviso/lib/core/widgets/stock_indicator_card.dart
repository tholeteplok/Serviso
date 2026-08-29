import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'neo_card.dart';

/// Centralized Stock Card with 4px left status border indicator
/// and bold IBM Plex Mono stock focal point, as defined in docs/design.md.
class StockIndicatorCard extends StatelessWidget {
  const StockIndicatorCard({
    super.key,
    required this.name,
    required this.code,
    required this.stockQty,
    required this.minStock,
    this.unit = 'pcs',
    this.sellPrice,
    this.costPrice,
    this.distributor,
    this.onTap,
  });

  final String name;
  final String? code;
  final double stockQty;
  final int minStock;
  final String unit;
  final double? sellPrice;
  final double? costPrice;
  final String? distributor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();

    // Determine status color indicator:
    // Red = Empty (0), Orange = Low stock (<= minStock), Green = Safe
    final Color indicatorColor;
    final String statusText;
    if (stockQty <= 0) {
      indicatorColor = AppColors.statusCancelled;
      statusText = 'Stok Habis';
    } else if (stockQty <= minStock) {
      indicatorColor = AppColors.statusWaiting;
      statusText = 'Stok Menipis';
    } else {
      indicatorColor = AppColors.statusDone;
      statusText = 'Stok Aman';
    }

    return NeoCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4px thick left border status accent
              Container(
                width: 5,
                color: indicatorColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (code != null && code!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.borderSubtle,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      code!,
                                      style: AppTypography.mono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: indicatorColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusText.toUpperCase(),
                                    style: TextStyle(
                                      color: indicatorColor == AppColors.statusWaiting
                                          ? AppColors.borderStrong
                                          : indicatorColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (distributor != null && distributor!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Distributor: ',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Large bold IBM Plex Mono stock focal point
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                stockQty.toStringAsFixed(
                                  stockQty.truncateToDouble() == stockQty ? 0 : 1,
                                ),
                                style: AppTypography.mono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: indicatorColor == AppColors.statusCancelled
                                      ? AppColors.statusCancelled
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                unit,
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Min:  ',
                            style: AppTypography.mono(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
