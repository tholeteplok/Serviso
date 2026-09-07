import 'package:flutter/material.dart';

import '../../../core/models/wo_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/status_stamp.dart';
import '../models/payment.dart';
import '../models/work_order.dart';

/// Authentic Work Order card aligned with serviso-ops-dashboard.html (.wo-card):
/// - Pastel status header strip with WO number and tilted -5° StatusStamp.
/// - Clean white body with Kalam bold vehicle/service title.
/// - Plate number, mechanic, and cost in sharp IBM Plex Mono tabular format.
class WoCard extends StatelessWidget {
  const WoCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  final WorkOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (order.vehicleDesc?.trim().isNotEmpty == true)
        ? '${order.vehicleDesc} — ${order.serviceLabel ?? order.complaint ?? 'Servis'}'
        : (order.customerName?.trim().isNotEmpty == true)
            ? '${order.customerName} — ${order.serviceLabel ?? order.complaint ?? 'Servis'}'
            : (order.serviceLabel ?? order.complaint ?? 'Servis');

    final cost = order.total;

    return NeoCard.pressable(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      headerColor: order.status.bgColor,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${order.woNumber} · ${timeId(order.createdAt)}',
            style: AppTypography.mono(
              fontSize: 12,
              color: AppColors.ink900,
              fontWeight: FontWeight.w600,
            ),
          ),
          StatusStamp(
            label: order.status.label,
            bgColor: order.status.bgColor,
            textColor: order.status.textColor,
            fontSize: 11,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle title in Kalam font
          Text(
            title,
            style: AppTypography.kalam(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Plate, Mechanic, Pit, and Cost in IBM Plex Mono & Inter
          Row(
            children: [
              if (order.plateNo != null && order.plateNo!.isNotEmpty) ...[
                Text(
                  order.plateNo!,
                  style: AppTypography.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
                Text(
                  ' · ',
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (order.assignedName != null && order.assignedName!.isNotEmpty) ...[
                Text(
                  order.assignedName!,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  ' · ',
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              Text(
                cost > 0 ? rupiah(cost) : 'Rp 0',
                style: AppTypography.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),

          // Selesai status: payment label
          if (order.status == WoStatus.selesai) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                StatusStamp(
                  label: order.paymentStatusLabel,
                  bgColor: order.isPaid
                      ? AppColors.statusDone
                      : AppColors.pastelPink,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                if (order.isPaid && order.payMethod != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    order.payMethod!.label,
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
