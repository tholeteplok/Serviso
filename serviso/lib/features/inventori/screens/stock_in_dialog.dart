import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_detail_controller.dart';
import '../models/part.dart';

Future<void> showStockInDialog(
  BuildContext context,
  WidgetRef ref,
  String partId, {
  Part? initialPart,
}) async {
  final qtyController = TextEditingController();
  final noteController = TextEditingController();
  final distributorController = TextEditingController();
  final priceController = TextEditingController(
    text: (initialPart != null && initialPart.costPrice > 0)
        ? initialPart.costPrice.toStringAsFixed(0)
        : '',
  );
  final formKey = GlobalKey<FormState>();
  final isAdmin = ref.read(isAdminProvider);

  var paymentType = 'tunai';
  var dueDate = DateTime.now().add(const Duration(days: 14));
  var updateCostPrice = true;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final textTheme = AppTypography.textTheme();
      final dateFormat = DateFormat('dd/MM/yyyy');

      return StatefulBuilder(
        builder: (context, setState) {
          final qty = double.tryParse(qtyController.text.trim()) ?? 0;
          final purchasePrice =
              double.tryParse(priceController.text.trim()) ?? 0;
          final totalCost = qty * purchasePrice;

          return AlertDialog(
            title: const Text('Stok Masuk'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jumlah / Qty
                    TextFormField(
                      controller: qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Masuk',
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Jumlah stok masuk harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Distributor / Pemasok
                    TextFormField(
                      controller: distributorController,
                      decoration: const InputDecoration(
                        labelText: 'Distributor / Pemasok (opsional)',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    // Status / Metode Pembayaran
                    Text(
                      'Metode Pembayaran',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'tunai',
                          label: Text('Tunai'),
                          icon: Icon(Icons.payments_outlined),
                        ),
                        ButtonSegment(
                          value: 'hutang',
                          label: Text('Hutang (Tempo)'),
                          icon: Icon(Icons.receipt_long_outlined),
                        ),
                      ],
                      selected: {paymentType},
                      onSelectionChanged: (set) {
                        setState(() => paymentType = set.first);
                      },
                    ),

                    // Jika Hutang: Picker Jatuh Tempo
                    if (paymentType == 'hutang') ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() => dueDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Jatuh Tempo: ${dateFormat.format(dueDate)}',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.inkMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Khusus Owner: Kolom Harga Beli
                    if (isAdmin) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'Informasi Finansial (Khusus Pemilik)',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli Satuan (Modal)',
                          prefixText: 'Rp ',
                          prefixIcon: Icon(Icons.price_change_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (qty > 0 && purchasePrice > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.tintOf(AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Pengeluaran:',
                                style: textTheme.bodySmall,
                              ),
                              Text(
                                rupiah(totalCost),
                                style: AppTypography.mono(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        value: updateCostPrice,
                        onChanged: (val) {
                          setState(() => updateCostPrice = val ?? true);
                        },
                        title: Text(
                          'Perbarui harga modal suku cadang ini',
                          style: textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    ],

                    const SizedBox(height: 8),
                    // Catatan
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan tambahan (opsional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final inputQty =
                            double.parse(qtyController.text.trim());
                        final double? inputPrice = isAdmin
                            ? double.tryParse(priceController.text.trim())
                            : null;

                        setState(() => saving = true);
                        try {
                          await ref
                              .read(partDetailControllerProvider(partId)
                                  .notifier)
                              .stockIn(
                                inputQty,
                                note: noteController.text,
                                distributor: distributorController.text,
                                purchasePrice: inputPrice,
                                paymentType: paymentType,
                                dueDate:
                                    paymentType == 'hutang' ? dueDate : null,
                                updateCostPrice:
                                    isAdmin && updateCostPrice,
                              );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stok masuk berhasil dicatat'),
                            ),
                          );
                        } catch (e) {
                          setState(() => saving = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}
