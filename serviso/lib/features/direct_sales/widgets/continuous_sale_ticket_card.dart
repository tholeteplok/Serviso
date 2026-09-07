import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/perforated_ticket_divider.dart';
import '../../../core/widgets/status_stamp.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../laporan/models/report_models.dart';
import '../../workorders/models/payment.dart';

/// Continuous ticket card widget for direct sales report.
/// Groups sales into a single physical roll/ledger with perforated tear lines:
/// - Pastel status header strip (.ticket-head)
/// - Clean white body with sales records
/// - PerforatedTicketDivider with circular notch cutouts between sales
/// - Tilted -5° StatusStamp for payment methods (TUNAI, QRIS, TRANSFER)
class ContinuousSaleTicketCard extends StatelessWidget {
  const ContinuousSaleTicketCard({
    super.key,
    required this.sales,
    required this.headerTitle,
    this.headerColor,
    this.onReprint,
  });

  final List<DirectSaleReportRow> sales;
  final String headerTitle;
  final Color? headerColor;
  final void Function(DirectSaleReportRow sale)? onReprint;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return const SizedBox.shrink();

    return NeoCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      headerColor: headerColor ?? AppColors.statusDone,
      header: Text(
        headerTitle,
        style: AppTypography.kalam(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink900,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < sales.length; i++) ...[
            _SaleTicketRow(
              sale: sales[i],
              onReprint: onReprint != null ? () => onReprint!(sales[i]) : null,
            ),
            if (i < sales.length - 1)
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

class _SaleTicketRow extends StatefulWidget {
  const _SaleTicketRow({
    required this.sale,
    this.onReprint,
  });

  final DirectSaleReportRow sale;
  final VoidCallback? onReprint;

  @override
  State<_SaleTicketRow> createState() => _SaleTicketRowState();
}

class _SaleTicketRowState extends State<_SaleTicketRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final payMethod = PaymentMethodX.fromValue(sale.payMethod);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Sale Number & Time + Tilted Payment Stamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.saleNumber,
                    style: AppTypography.mono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeId(sale.paidAt),
                    style: AppTypography.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              StatusStamp(
                label: payMethod.label,
                bgColor: AppColors.pastelMint,
                textColor: AppColors.ink900,
                fontSize: 11,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Customer & Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sale.customerName?.isNotEmpty == true
                    ? 'Pelanggan: ${sale.customerName}'
                    : 'Pelanggan: Umum',
                style: AppTypography.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                rupiah(sale.paidAmount),
                style: AppTypography.mono(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),

          // Collapsible Items Detail
          if (sale.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sale.items.length} Rincian Item',
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(
                      _expanded ? AppIcons.caretUp : AppIcons.caretDown,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 4),
              for (final item in sale.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: AppTypography.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                            ),
                            Text(
                              '${item.qty.toInt()} x ${rupiah(item.unitPrice)}${item.discount > 0 ? ' (diskon -${rupiah(item.discount)})' : ''}',
                              style: AppTypography.mono(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        rupiah((item.qty * item.unitPrice) - item.discount),
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],

          // Reprint action
          if (widget.onReprint != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ThickBottomBorderButton(
                size: ThickButtonSize.compact,
                variant: ThickButtonVariant.secondary,
                onPressed: widget.onReprint,
                icon: Icon(AppIcons.receipt, size: 14),
                child: const Text('Cetak Struk'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
