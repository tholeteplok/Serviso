import 'package:flutter/material.dart';

import '../../../core/models/wo_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/plate_chip.dart';
import '../models/payment.dart';
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

    return NeoCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderWidth: 2.0,
      borderColor: AppColors.borderInk,
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
                          ? AppColors.pastelCream
                          : AppColors.pastelMint,
                      border: Border.all(
                        color: AppColors.borderInk,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial ?? '—',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.ink900,
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
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (order.status == WoStatus.selesai) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: order.isPaid
                            ? AppColors.statusDone
                            : AppColors.pastelPink,
                        borderRadius: AppRadius.pill,
                        border: Border.all(
                          color: AppColors.borderInk,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        order.paymentStatusLabel,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                    ),
                    if (order.isPaid && order.payMethod != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: AppRadius.pill,
                          border: Border.all(
                            color: AppColors.borderInk,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          order.payMethod!.label,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                    ],
                  ],
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
    );
  }
}
