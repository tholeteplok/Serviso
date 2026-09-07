import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

import 'status_stamp.dart';

/// Centralized Stock Card with single 1.2px ink border,
/// bold IBM Plex Mono numbers, and tilted -5° StatusStamp on the right.
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
      statusText = 'Habis';
    } else if (stockQty <= minStock) {
      indicatorColor = AppColors.pastelYellow;
      statusText = 'Menipis';
    } else {
      indicatorColor = AppColors.pastelMint;
      statusText = 'Aman';
    }

    final priceStr = sellPrice != null && sellPrice! > 0
        ? ' · Rp ${sellPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderStrong, width: 1.2),
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
                // Item Details (Left)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${code ?? '-'}$priceStr',
                        style: AppTypography.mono(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (distributor != null && distributor!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Distributor: $distributor',
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

                // Large bold IBM Plex Mono stock + tilted StatusStamp (Right)
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
                            fontSize: 20,
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
                    const SizedBox(height: 6),
                    StatusStamp(
                      label: statusText,
                      bgColor: indicatorColor,
                      fontSize: 11,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
