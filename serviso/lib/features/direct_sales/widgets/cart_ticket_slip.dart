import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_stepper.dart';
import '../../../core/widgets/perforated_ticket_divider.dart';
import '../../workorders/models/work_order.dart';
import '../models/direct_sale.dart';

/// Authentic physical receipt slip widget for Direct Sale Cart.
/// Aligned with Craftsman Field Ledger v3.0:
/// - Pastel mint header strip (.ticket-head)
/// - Clean white body with item rows
/// - PerforatedTicketDivider separating items with circular notch cutouts
class CartTicketSlip extends StatelessWidget {
  const CartTicketSlip({
    super.key,
    required this.items,
    required this.onQtyChanged,
    required this.onRemoveItem,
  });

  final List<DirectSaleItemInput> items;
  final void Function(int index, double newQty) onQtyChanged;
  final void Function(int index) onRemoveItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Keranjang masih kosong',
            style: AppTypography.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final totalAmount = items.fold(0.0, (s, e) => s + e.lineTotal);

    return NeoCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      headerColor: AppColors.pastelMint,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(AppIcons.receipt, size: 16, color: AppColors.ink900),
              const SizedBox(width: 6),
              Text(
                'DRAF STRUK · ${items.length} ITEM',
                style: AppTypography.kalam(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
          Text(
            rupiah(totalAmount),
            style: AppTypography.mono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                children: [
                  // Item Kind Badge
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: items[i].kind == WoItemKind.jasa
                          ? AppColors.pastelAmber
                          : AppColors.pastelMint,
                      borderRadius: AppRadius.sm,
                      border: Border.all(
                        color: AppColors.borderInk,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      items[i].kind == WoItemKind.jasa
                          ? AppIcons.wrench
                          : AppIcons.inventory,
                      size: 16,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Item Name & Price breakdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].description ?? 'Item',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${rupiah(items[i].unitPrice)} x ${items[i].qty.toInt()} = ${rupiah(items[i].lineTotal)}',
                          style: AppTypography.mono(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stepper & Delete Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeoStepper(
                        value: items[i].qty,
                        min: 1,
                        size: NeoStepperSize.compact,
                        fixedWidth: 92,
                        onChanged: (newQty) =>
                            onQtyChanged(i, newQty.toDouble()),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          AppIcons.trash,
                          size: 16,
                          color: AppColors.statusDanger,
                        ),
                        onPressed: () => onRemoveItem(i),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              const PerforatedTicketDivider(
                notchRadius: 8.0,
                lineColor: AppColors.borderInk,
                notchBgColor: AppColors.canvas,
                notchBorderColor: AppColors.borderInk,
                borderWidth: 1.2,
              ),
          ],
        ],
      ),
    );
  }
}
