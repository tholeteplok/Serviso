import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Centralized Stock Card with solid 1.5px black border,
/// 3.5px hard pop shadow, and bold IBM Plex Mono stock focal point.
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
    // Red = Empty (0), Orange/Yellow = Low stock (<= minStock), Green = Safe
    final Color indicatorColor;
    final String statusText;
    if (stockQty <= 0) {
      indicatorColor = AppColors.pastelPink;
      statusText = 'Stok Habis';
    } else if (stockQty <= minStock) {
      indicatorColor = AppColors.pastelYellow;
      statusText = 'Stok Menipis';
    } else {
      indicatorColor = AppColors.pastelMint;
      statusText = 'Stok Aman';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderStrong,
            offset: Offset(0, 3.5),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.card,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
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
                          color: AppColors.ink900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (code != null && code!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pastelCream,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.borderStrong,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                code!,
                                style: AppTypography.mono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.borderStrong,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: AppColors.ink900,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (distributor != null && distributor!.isNotEmpty) ...[
                        const SizedBox(height: 6),
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
                            color: stockQty <= 0
                                ? AppColors.statusCancelledBorder
                                : AppColors.ink900,
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
      ),
    );
  }
}
