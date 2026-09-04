import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../controllers/wo_detail_controller.dart';
import '../models/payment.dart';
import '../models/work_order.dart';

class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key, required this.order, this.onPaid});

  final WorkOrder order;
  final VoidCallback? onPaid;

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  late final TextEditingController _amountController;
  PaymentMethod _method = PaymentMethod.cash;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.order.total.toStringAsFixed(0));
    _method = widget.order.payMethod ?? PaymentMethod.cash;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _parsedAmount() {
    final raw = _amountController.text.replaceAll('.', '').trim();
    return double.tryParse(raw) ?? -1;
  }

  Future<void> _save() async {
    final amount = _parsedAmount();
    final validation = validatePaymentAmount(amount, widget.order.total);
    if (!validation.isValid) {
      setState(() => _error = validation.error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(woDetailControllerProvider(widget.order.id).notifier)
          .pay(paidAmount: amount, payMethod: _method);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPaid?.call();
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final total = widget.order.total;

    return NeoBottomSheet(
      title: 'Pembayaran',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Tagihan', style: textTheme.titleMedium),
              Text(
                rupiah(total),
                style: AppTypography.mono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeoTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            labelText: 'Nominal dibayar',
            prefixText: 'Rp ',
            style: AppTypography.mono(
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Metode pembayaran',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          NeoSegmentControl<PaymentMethod>(
            items: PaymentMethod.values
                .map(
                  (m) => NeoSegmentItem<PaymentMethod>(
                    value: m,
                    label: m.label,
                  ),
                )
                .toList(),
            selectedValue: _method,
            onValueChanged: (m) => setState(() => _method = m),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.statusDanger),
            ),
          ],
          const SizedBox(height: 20),
          ThickBottomBorderButton(
            isFullWidth: true,
            variant: ThickButtonVariant.primary,
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.ink900,
                    ),
                  )
                : const Text('Simpan Pembayaran'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
