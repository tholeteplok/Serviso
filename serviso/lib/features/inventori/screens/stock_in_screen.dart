import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/distributor_autocomplete_field.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_detail_controller.dart';
import '../models/part.dart';

/// Screen dedicated to recording incoming stock for inventory items.
/// Migrated from a cramped floating dialog to a full-featured screen with
/// spacious form sections, autocomplete support, and keyboard adaptability.
class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({
    super.key,
    required this.partId,
    this.initialPart,
  });

  final String partId;
  final Part? initialPart;

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _qtyController;
  late final TextEditingController _distributorController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;

  String _paymentType = 'tunai';
  late DateTime _dueDate;
  bool _updateCostPrice = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _distributorController = TextEditingController();
    _priceController = TextEditingController(
      text: (widget.initialPart != null && widget.initialPart!.costPrice > 0)
          ? widget.initialPart!.costPrice.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController();
    _dueDate = DateTime.now().add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _distributorController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isAdmin = ref.read(isAdminProvider);
    final inputQty = double.parse(_qtyController.text.trim());
    final double? inputPrice = isAdmin
        ? double.tryParse(_priceController.text.trim())
        : null;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(partDetailControllerProvider(widget.partId).notifier)
          .stockIn(
            inputQty,
            note: _noteController.text,
            distributor: _distributorController.text,
            purchasePrice: inputPrice,
            paymentType: _paymentType,
            dueDate: _paymentType == 'hutang' ? _dueDate : null,
            updateCostPrice: isAdmin && _updateCostPrice,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok masuk berhasil dicatat')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.read(isAdminProvider);
    final textTheme = AppTypography.textTheme();
    final dateFormat = DateFormat('dd/MM/yyyy');

    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    final purchasePrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final totalCost = qty * purchasePrice;

    final part = widget.initialPart;

    return Scaffold(
      appBar: const NeoAppBar(
        title: 'Stok Masuk',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan Barang
              if (part != null) ...[
                NeoCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.pastelMint,
                          borderRadius: AppRadius.button,
                          border: Border.all(color: AppColors.borderInk, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Icon(AppIcons.part, size: 22, color: AppColors.ink900),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              part.name,
                              style: AppTypography.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stok saat ini: ${part.stockQty.toStringAsFixed(0)} ${part.unit ?? "pcs"}',
                              style: AppTypography.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Jumlah & Pemasok
              SectionCard(
                title: 'Jumlah & Pemasok',
                child: Column(
                  children: [
                    NeoTextField(
                      controller: _qtyController,
                      labelText: 'Jumlah Masuk *',
                      hintText: 'Misal: 10',
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
                    DistributorAutocompleteField(
                      controller: _distributorController,
                      labelText: _paymentType == 'hutang'
                          ? 'Distributor / Pemasok *'
                          : 'Distributor / Pemasok (opsional)',
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (_paymentType == 'hutang' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Distributor wajib diisi untuk hutang';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Metode Pembayaran
              SectionCard(
                title: 'Metode Pembayaran',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdmin)
                      NeoSegmentControl<String>(
                        selectedValue: _paymentType,
                        onValueChanged: (val) => setState(() => _paymentType = val),
                        items: [
                          NeoSegmentItem<String>(
                            value: 'tunai',
                            label: 'Tunai',
                            icon: Icon(AppIcons.wallet, size: 16),
                          ),
                          NeoSegmentItem<String>(
                            value: 'hutang',
                            label: 'Hutang / Tempo',
                            icon: Icon(AppIcons.receipt, size: 16),
                          ),
                        ],
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
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
                                'Tunai (Hutang hanya dapat dicatat oleh Admin)',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_paymentType == 'hutang') ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        borderRadius: AppRadius.input,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderInk, width: 1.5),
                            borderRadius: AppRadius.input,
                            color: AppColors.bgSurface,
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
                                  'Jatuh Tempo: ${dateFormat.format(_dueDate)}',
                                  style: AppTypography.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink900,
                                  ),
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Finansial Khusus Pemilik
              if (isAdmin) ...[
                SectionCard(
                  title: 'Informasi Finansial (Khusus Pemilik)',
                  child: Column(
                    children: [
                      NeoTextField(
                        controller: _priceController,
                        labelText: _paymentType == 'hutang'
                            ? 'Harga Beli Satuan *'
                            : 'Harga Beli Satuan (Modal)',
                        prefixText: 'Rp ',
                        prefixIcon: AppIcons.wallet,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (_paymentType == 'hutang') {
                            final p = double.tryParse(value?.trim() ?? '');
                            if (p == null || p <= 0) {
                              return 'Harga beli wajib > 0 untuk pencatatan hutang';
                            }
                          }
                          return null;
                        },
                      ),
                      if (qty > 0 && purchasePrice > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pastelMint.withValues(alpha: 0.35),
                            borderRadius: AppRadius.chipSmall,
                            border: Border.all(color: AppColors.borderInk, width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Pengeluaran:',
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink900,
                                ),
                              ),
                              Text(
                                rupiah(totalCost),
                                style: AppTypography.mono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        value: _updateCostPrice,
                        onChanged: (val) {
                          setState(() => _updateCostPrice = val ?? true);
                        },
                        title: Text(
                          'Perbarui harga modal beli barang ini',
                          style: AppTypography.inter(
                            fontSize: 13,
                            color: AppColors.ink900,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Catatan Tambahan
              SectionCard(
                title: 'Catatan Tambahan',
                child: NeoTextField(
                  controller: _noteController,
                  labelText: 'Catatan (opsional)',
                  hintText: 'Misal: Nota #1234, barang titipan, dll',
                  prefixIcon: AppIcons.notepad,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(
            top: BorderSide(color: AppColors.borderHairline, width: 1),
          ),
        ),
        child: SafeArea(
          child: ThickBottomBorderButton(
            onPressed: _isSaving ? null : _submit,
            isLoading: _isSaving,
            isFullWidth: true,
            variant: ThickButtonVariant.primary,
            child: Text(
              'Simpan Stok Masuk',
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
