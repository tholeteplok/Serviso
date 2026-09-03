import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/distributor_autocomplete_field.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
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

  await showNeoDialog<void>(
    context: context,
    child: StatefulBuilder(
      builder: (context, setState) {
        final textTheme = AppTypography.textTheme();
        final dateFormat = DateFormat('dd/MM/yyyy');
        final qty = double.tryParse(qtyController.text.trim()) ?? 0;
        final purchasePrice =
            double.tryParse(priceController.text.trim()) ?? 0;
        final totalCost = qty * purchasePrice;

        return NeoDialog.alert(
          title: 'Stok Masuk',
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jumlah / Qty
                  NeoTextField(
                    controller: qtyController,
                    labelText: 'Jumlah Masuk',
                    prefixIcon: AppIcons.tag,
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

                    // Distributor / Pemasok — wajib jika hutang (DB hutang perlu jejak)
                    DistributorAutocompleteField(
                      controller: distributorController,
                      labelText: paymentType == 'hutang'
                          ? 'Distributor / Pemasok *'
                          : 'Distributor / Pemasok (opsional)',
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (paymentType == 'hutang' && (value == null || value.trim().isEmpty)) {
                          return 'Distributor wajib diisi untuk hutang';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Status / Metode Pembayaran — hutang hanya admin
                    Text(
                      'Metode Pembayaran',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isAdmin)
                      NeoSegmentControl<String>(
                        selectedValue: paymentType,
                        onValueChanged: (val) => setState(() => paymentType = val),
                        items: [
                          NeoSegmentItem<String>(
                            value: 'tunai',
                            label: 'Tunai',
                            activeColor: AppColors.pastelMint,
                            icon: Icon(AppIcons.wallet, size: 16),
                          ),
                          NeoSegmentItem<String>(
                            value: 'hutang',
                            label: 'Hutang',
                            activeColor: AppColors.pastelYellow,
                            icon: Icon(AppIcons.receipt, size: 16),
                          ),
                        ],
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.pastelMint.withValues(alpha: 0.3),
                          borderRadius: AppRadius.chipSmall,
                          border: Border.all(color: AppColors.borderStrong, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Icon(AppIcons.wallet, size: 16, color: AppColors.ink900),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tunai (Hutang hanya oleh Admin)',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                        borderRadius: AppRadius.input,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderInk, width: 1.5),
                            borderRadius: AppRadius.input,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.calendar,
                                color: AppColors.accentPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Jatuh Tempo: ${dateFormat.format(dueDate)}',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              Icon(
                                AppIcons.caretDown,
                                color: AppColors.textSecondary,
                                size: 16,
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
                          color: AppColors.accentPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeoTextField(
                        controller: priceController,
                        labelText: paymentType == 'hutang'
                            ? 'Harga Beli Satuan *'
                            : 'Harga Beli Satuan (Modal)',
                        prefixText: 'Rp ',
                        prefixIcon: AppIcons.wallet,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (paymentType == 'hutang') {
                            final p = double.tryParse(value?.trim() ?? '');
                            if (p == null || p <= 0) return 'Harga beli wajib >0 untuk hutang';
                          }
                          return null;
                        },
                      ),
                      if (qty > 0 && purchasePrice > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.tintOf(AppColors.accentPrimary),
                            borderRadius: AppRadius.chipSmall,
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
                                  color: AppColors.accentPrimary,
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
                    NeoTextField(
                      controller: noteController,
                      labelText: 'Catatan tambahan (opsional)',
                      prefixIcon: AppIcons.notepad,
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
              const SizedBox(width: 8),
              ThickBottomBorderButton(
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
      ),
    );
  }
