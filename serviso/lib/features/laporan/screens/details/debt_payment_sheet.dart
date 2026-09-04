import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/neo_bottom_sheet.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_segment_control.dart';
import '../../../../core/widgets/thick_bottom_border_button.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';

class DebtPaymentSheet extends ConsumerStatefulWidget {
  final DistributorDebtItem debt;
  final WidgetRef parentRef;

  const DebtPaymentSheet({
    super.key,
    required this.debt,
    required this.parentRef,
  });

  static Future<void> show(BuildContext context, WidgetRef ref, DistributorDebtItem debt) {
    return showNeoBottomSheet(
      context: context,
      title: 'Bayar Hutang Distributor',
      child: DebtPaymentSheet(debt: debt, parentRef: ref),
    );
  }

  @override
  ConsumerState<DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends ConsumerState<DebtPaymentSheet> {
  late TextEditingController _amountController;
  final _noteController = TextEditingController();
  String _payMethod = 'Tunai';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final remaining = widget.debt.remaining;
    _amountController = TextEditingController(
      text: remaining > 0 ? remaining.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handlePay() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah bayar harus lebih dari 0')),
      );
      return;
    }

    if (amount > widget.debt.remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah bayar tidak boleh melebihi sisa hutang')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.parentRef.read(reportRepositoryProvider).payDebt(
            movementId: widget.debt.movementId,
            amount: amount,
            payMethod: _payMethod,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          );

      widget.parentRef.invalidate(distributorDebtsProvider);
      widget.parentRef.invalidate(ownerFinancialSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran berhasil dicatat')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencatat pembayaran: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bayar Hutang',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeoCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.debt.distributor,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.debt.partName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Hutang', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.inkMuted)),
                    Text(
                      rupiah(widget.debt.totalDebt),
                      style: AppTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Terbayar', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.inkMuted)),
                    Text(
                      rupiah(widget.debt.totalPaid),
                      style: AppTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sisa Hutang', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      rupiah(widget.debt.remaining),
                      style: AppTypography.mono(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.debt.remaining > 0 ? AppColors.action : AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('debt_amount'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Jumlah Bayar',
              prefixText: 'Rp ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Metode Pembayaran',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          NeoSegmentControl<String>(
            selectedValue: _payMethod,
            onValueChanged: (val) => setState(() => _payMethod = val),
            items: const [
              NeoSegmentItem<String>(value: 'Tunai', label: 'Tunai'),
              NeoSegmentItem<String>(value: 'Transfer', label: 'Transfer'),
              NeoSegmentItem<String>(value: 'QRIS', label: 'QRIS'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('debt_note'),
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Catatan (Opsional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          ThickBottomBorderButton(
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handlePay,
            child: Text(
              _isLoading ? 'Memproses...' : 'Bayar',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

