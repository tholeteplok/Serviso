import 'package:flutter/material.dart';

import '../../../core/models/wo_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/perforated_ticket_divider.dart';
import '../../../core/widgets/status_stamp.dart';
import '../models/work_order.dart';

/// Continuous tear-off ticket roll card for workshop queue (antrean).
/// Binds multiple work orders into a single physical-looking ticket strip
/// connected by [PerforatedTicketDivider] with circular side notches.
class ContinuousTicketCard extends StatelessWidget {
  const ContinuousTicketCard({
    super.key,
    required this.orders,
    this.headerTitle,
    this.headerColor = AppColors.pastelYellow,
    this.headerTrailing,
    this.onOrderTap,
  });

  final List<WorkOrder> orders;
  final String? headerTitle;
  final Color headerColor;
  final Widget? headerTrailing;
  final void Function(WorkOrder order)? onOrderTap;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.borderInk,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowWarm,
            offset: Offset(3.0, 3.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip (Pastel)
          if (headerTitle != null || headerTrailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: headerColor,
                border: const Border(
                  bottom: BorderSide(
                    color: AppColors.borderInk,
                    width: 1.2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (headerTitle != null)
                    Expanded(
                      child: Text(
                        headerTitle!,
                        style: AppTypography.kalam(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                    ),
                  ?headerTrailing,
                ],
              ),
            ),

          // Perforated ticket items
          for (int i = 0; i < orders.length; i++) ...[
            _TicketItemRow(
              order: orders[i],
              onTap: onOrderTap != null ? () => onOrderTap!(orders[i]) : null,
            ),
            if (i < orders.length - 1)
              const PerforatedTicketDivider(
                notchRadius: 9.0,
                lineColor: AppColors.borderInk,
                notchBgColor: AppColors.bgBase,
                notchBorderColor: AppColors.borderInk,
                borderWidth: 1.2,
              ),
          ],
        ],
      ),
    );
  }
}

class _TicketItemRow extends StatelessWidget {
  const _TicketItemRow({
    required this.order,
    this.onTap,
  });

  final WorkOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = (order.vehicleDesc?.trim().isNotEmpty == true)
        ? '${order.vehicleDesc} — ${order.serviceLabel ?? order.complaint ?? 'Servis'}'
        : (order.customerName?.trim().isNotEmpty == true)
            ? '${order.customerName} — ${order.serviceLabel ?? order.complaint ?? 'Servis'}'
            : (order.serviceLabel ?? order.complaint ?? 'Servis');

    final cost = order.displayCost;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.pastelCream,
        highlightColor: AppColors.pastelCream.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: WO number & time + status stamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 6),

              // Title: Vehicle / Customer in Kalam font
              Text(
                title,
                style: AppTypography.kalam(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Subtitle: Plate, Mechanic, Cost in IBM Plex Mono & Inter
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
            ],
          ),
        ),
      ),
    );
  }
}
