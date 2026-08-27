import 'package:flutter/material.dart';

import '../../../core/models/wo_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/plate_chip.dart';
import '../models/work_order.dart';

class WoCard extends StatelessWidget {
  const WoCard({super.key, required this.order, required this.onTap});

  final WorkOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final initial = (order.assignedName?.trim().isNotEmpty == true)
        ? order.assignedName!.trim()[0].toUpperCase()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlateChip(plateText: order.plateNo ?? '—'),
                  const Spacer(),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: initial == null
                          ? AppColors.line
                          : AppColors.tintOf(AppColors.teal),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial ?? '—',
                      style: textTheme.labelLarge?.copyWith(
                        color: initial == null
                            ? AppColors.inkMuted
                            : AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.customerName ?? 'Pelanggan',
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                order.complaint ?? '—',
                style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (order.status == WoStatus.selesai) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: order.isPaid
                        ? AppColors.tintOf(AppColors.teal)
                        : AppColors.tintOf(AppColors.inkMuted),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.paymentStatusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: order.isPaid
                          ? AppColors.teal
                          : AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                timeId(order.createdAt),
                style: AppTypography.mono(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
