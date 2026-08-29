import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neo_segment_control.dart';
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pembayaran', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: textTheme.titleMedium),
              Text(
                rupiah(total),
                style: AppTypography.mono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal dibayar',
              prefixText: 'Rp ',
            ),
            style: AppTypography.mono(),
          ),
          const SizedBox(height: 8),
          Text('Metode pembayaran', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          NeoSegmentControl<PaymentMethod>(
            items: PaymentMethod.values
                .map(
                  (m) => NeoSegmentItem<PaymentMethod>(
                    value: m,
                    label: m.label,
                    activeColor: AppColors.pastelMint,
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
              style: textTheme.bodyMedium?.copyWith(color: AppColors.action),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : const Text('Simpan Pembayaran'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
