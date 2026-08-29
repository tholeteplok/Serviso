import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_form_controller.dart';
import '../controllers/part_list_controller.dart';
import '../models/part.dart';

void showPartForm(
  BuildContext context,
  WidgetRef ref,
  Part? initial, {
  VoidCallback? onSaved,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PartFormSheet(initial: initial, onSaved: onSaved),
  );
}

class PartFormSheet extends ConsumerStatefulWidget {
  const PartFormSheet({super.key, this.initial, this.onSaved});

  final Part? initial;
  final VoidCallback? onSaved;

  @override
  ConsumerState<PartFormSheet> createState() => _PartFormSheetState();
}

class _PartFormSheetState extends ConsumerState<PartFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _minStockController;
  late final TextEditingController _costController;
  late final TextEditingController _sellController;
  late final TextEditingController _unitController;
  late final TextEditingController _initialStockController;
  late final TextEditingController _distributorController;
  var _paymentType = 'tunai';
  late DateTime _dueDate;

  static const List<String> _unitOptions = [
    'pcs',
    'botol',
    'set',
    'liter',
    'meter',
    'roll',
    'pack',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _codeController = TextEditingController(
      text: initial?.code ?? (initial == null ? suggestPartCode() : ''),
    );
    _minStockController = TextEditingController(
      text: initial?.minStock.toString() ?? '0',
    );
    _costController = TextEditingController(
      text: initial != null ? initial.costPrice.toString() : '',
    );
    _sellController = TextEditingController(
      text: initial != null ? initial.sellPrice.toString() : '',
    );
    _unitController = TextEditingController(text: initial?.unit ?? 'pcs');
    _initialStockController = TextEditingController();
    _distributorController = TextEditingController();
    _dueDate = DateTime.now().add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _unitController.dispose();
    _initialStockController.dispose();
    _distributorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isAdmin = ref.read(isAdminProvider);
    final controller =
        ref.read(partFormControllerProvider(widget.initial).notifier);
    final minStock =
        int.tryParse(_minStockController.text.trim()) ?? 0;
    final cost = isAdmin ? double.tryParse(_costController.text) : null;
    final sell = isAdmin ? double.tryParse(_sellController.text) : null;

    final isEdit = widget.initial != null;
    final initialStock = !isEdit
        ? (double.tryParse(_initialStockController.text.trim()) ?? 0.0)
        : 0.0;
    final rawDistributor = !isEdit ? _distributorController.text.trim() : null;
    final distributor =
        rawDistributor?.isEmpty == true ? null : rawDistributor;
    final paymentType = !isEdit ? _paymentType : 'tunai';
    final dueDate = (!isEdit && paymentType == 'hutang') ? _dueDate : null;

    try {
      await controller.submit(
        name: _nameController.text,
        code: _codeController.text,
        unit: _unitController.text,
        minStock: minStock < 0 ? 0 : minStock,
        costPrice: cost,
        sellPrice: sell,
        initialStock: initialStock,
        distributor: distributor,
        paymentType: paymentType,
        dueDate: dueDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(partListControllerProvider);
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final isEdit = widget.initial != null;
    final isAdmin = ref.watch(isAdminProvider);
    final state = ref.watch(partFormControllerProvider(widget.initial));
    final saving = state.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Ubah Suku Cadang' : 'Tambah Suku Cadang',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(AppIcons.tag),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama suku cadang wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Kode',
                  prefixIcon: Icon(AppIcons.tag),
                  helperText: 'Saran kode otomatis, atau scan barcode',
                  suffixIcon: IconButton(
                    icon: Icon(AppIcons.barcode),
                    tooltip: 'Scan Barcode',
                    onPressed: () async {
                      final code = await showBarcodeScanner(context);
                      if (code != null && code.isNotEmpty) {
                        setState(() {
                          _codeController.text = code;
                        });
                      }
                    },
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownMenu<String>(
                controller: _unitController,
                width: double.infinity,
                label: const Text('Unit'),
                leadingIcon: Icon(AppIcons.tag),
                enableFilter: true,
                requestFocusOnTap: true,
                initialSelection: widget.initial?.unit ?? 'pcs',
                onSelected: (_) {},
                dropdownMenuEntries: _unitOptions
                    .map((u) => DropdownMenuEntry(value: u, label: u))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minStockController,
                decoration: InputDecoration(
                  labelText: 'Batas Stok Menipis',
                  prefixIcon: Icon(AppIcons.warning),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (int.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (isAdmin) ...[
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: 'Modal Beli (Rp)',
                    prefixIcon: Icon(AppIcons.cart),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sellController,
                  decoration: InputDecoration(
                    labelText: 'Harga Jual (Rp)',
                    prefixIcon: Icon(AppIcons.money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tintPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Harga diatur oleh pemilik. Suku cadang ditambahkan '
                    'tanpa harga.',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
              if (!isEdit) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderStrong, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.borderStrong,
                        offset: Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppIcons.inventory,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pengadaan Stok Awal (Opsional)',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _initialStockController,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Stok Awal (Qty)',
                          hintText: 'Misal: 10 (kosongkan jika belum ada)',
                          prefixIcon: Icon(AppIcons.cart),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Masukkan jumlah stok yang valid (>= 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _distributorController,
                        decoration: InputDecoration(
                          labelText: 'Distributor / Pemasok (opsional)',
                          hintText: 'Misal: PT Astra Otoparts',
                          prefixIcon: Icon(AppIcons.truck),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Metode Pembayaran',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeoSegmentControl<String>(
                        selectedValue: _paymentType,
                        onValueChanged: (val) => setState(() => _paymentType = val),
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
                      ),
                      if (_paymentType == 'hutang') ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderStrong, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  AppIcons.calendar,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jatuh Tempo: ${DateFormat('dd/MM/yyyy').format(_dueDate)}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                Icon(
                                  AppIcons.caretDown,
                                  color: AppColors.inkMuted,
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
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: Icon(AppIcons.check, size: 18),
                  onPressed: saving ? null : _submit,
                  label: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
