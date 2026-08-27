import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_form_controller.dart';
import '../controllers/part_list_controller.dart';
import '../models/part.dart';

void showPartForm(BuildContext context, WidgetRef ref, Part? initial) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PartFormSheet(initial: initial),
  );
}

class PartFormSheet extends ConsumerStatefulWidget {
  const PartFormSheet({super.key, this.initial});

  final Part? initial;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _unitController.dispose();
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
    try {
      await controller.submit(
        name: _nameController.text,
        code: _codeController.text,
        unit: _unitController.text,
        minStock: minStock < 0 ? 0 : minStock,
        costPrice: cost,
        sellPrice: sell,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(partListControllerProvider);
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
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.label_outline),
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
                decoration: const InputDecoration(
                  labelText: 'Kode',
                  prefixIcon: Icon(Icons.tag_outlined),
                  helperText: 'Saran kode otomatis, dapat diubah',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownMenu<String>(
                controller: _unitController,
                width: double.infinity,
                label: const Text('Unit'),
                leadingIcon: const Icon(Icons.straighten_outlined),
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
                decoration: const InputDecoration(
                  labelText: 'Batas Stok Menipis',
                  prefixIcon: Icon(Icons.warning_outlined),
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
                  decoration: const InputDecoration(
                    labelText: 'Modal Beli (Rp)',
                    prefixIcon: Icon(Icons.shopping_cart_outlined),
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
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual (Rp)',
                    prefixIcon: Icon(Icons.sell_outlined),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : _submit,
                  child: saving
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
