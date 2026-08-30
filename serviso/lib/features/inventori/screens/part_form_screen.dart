import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_detail_controller.dart';
import '../controllers/part_form_controller.dart';
import '../controllers/part_list_controller.dart';
import '../models/part.dart';

class PartFormScreen extends ConsumerStatefulWidget {
  const PartFormScreen({super.key, this.partId, this.initial});

  final String? partId;
  final Part? initial;

  @override
  ConsumerState<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends ConsumerState<PartFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _minStockController;
  late final TextEditingController _costController;
  late final TextEditingController _sellController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _distributorController;
  var _paymentType = 'tunai';
  late DateTime _dueDate;
  bool _loadingPart = false;
  Part? _resolvedInitial;

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
    _resolvedInitial = widget.initial;
    final initial = _resolvedInitial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _codeController = TextEditingController(
      text: initial?.code ?? (initial == null ? suggestPartCode() : ''),
    );
    _minStockController = TextEditingController(
      text: initial?.minStock.toString() ?? '0',
    );
    _costController = TextEditingController(
      text: initial != null ? initial.costPrice.toStringAsFixed(0) : '',
    );
    _sellController = TextEditingController(
      text: initial != null ? initial.sellPrice.toStringAsFixed(0) : '',
    );
    _unitController = TextEditingController(text: initial?.unit ?? 'pcs');
    _quantityController = TextEditingController();
    _distributorController = TextEditingController();
    _dueDate = DateTime.now().add(const Duration(days: 14));

    if (widget.partId != null && _resolvedInitial == null) {
      _fetchPart();
    }
  }

  Future<void> _fetchPart() async {
    setState(() => _loadingPart = true);
    try {
      final data = await ref.read(partDetailControllerProvider(widget.partId!).future);
      final part = data.part;
      if (!mounted) return;
      setState(() {
        _resolvedInitial = part;
        _nameController.text = part.name;
        _codeController.text = part.code ?? '';
        _minStockController.text = part.minStock.toString();
        _costController.text = part.costPrice == 0 ? '' : part.costPrice.toStringAsFixed(0);
        _sellController.text = part.sellPrice == 0 ? '' : part.sellPrice.toStringAsFixed(0);
        _unitController.text = part.unit ?? 'pcs';
      });
    } catch (_) {
      // keep empty for create fallback
    } finally {
      if (mounted) setState(() => _loadingPart = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _distributorController.dispose();
    super.dispose();
  }

  bool get _isEdit => _resolvedInitial != null || widget.partId != null;

  Part? get _effectiveInitial => _resolvedInitial ?? widget.initial;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isAdmin = ref.read(isAdminProvider);
    final controller =
        ref.read(partFormControllerProvider(_effectiveInitial).notifier);
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 0;
    final cost = isAdmin ? double.tryParse(_costController.text) : null;
    final sell = isAdmin ? double.tryParse(_sellController.text) : null;

    final isEdit = _isEdit;
    final initialStock = !isEdit
        ? (double.tryParse(_quantityController.text.trim()) ?? 0.0)
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
      ref.invalidate(partListControllerProvider);
      if (widget.partId != null) {
        ref.invalidate(partDetailControllerProvider(widget.partId!));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Suku cadang diperbarui' : 'Suku cadang ditambahkan')),
        );
        context.pop();
      }
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
    final isEdit = _isEdit;
    final isAdmin = ref.watch(isAdminProvider);
    final state = ref.watch(partFormControllerProvider(_effectiveInitial));
    final saving = state.isLoading;

    if (_loadingPart) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(AppIcons.back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Memuat...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back),
          tooltip: 'Kembali',
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? 'Ubah Suku Cadang' : 'Tambah Suku Cadang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'Informasi Dasar',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama *',
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
                      initialSelection: _effectiveInitial?.unit ?? 'pcs',
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
                        helperText: 'Peringatan jika stok <= nilai ini',
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isAdmin) ...[
                SectionCard(
                  title: 'Harga',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _costController,
                        decoration: InputDecoration(
                          labelText: 'Modal Beli (Rp)',
                          prefixIcon: Icon(AppIcons.cart),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          if (double.tryParse(value) == null) {
                            return 'Masukkan angka yang valid';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tintPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderStrong, width: 1.5),
                  ),
                  child: Text(
                    'Harga diatur oleh pemilik. Suku cadang ditambahkan tanpa harga.',
                    style: textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!isEdit) ...[
                SectionCard(
                  title: 'Kuantitas',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Kuantitas *',
                          hintText: 'Misal: 10 (isi 0 jika belum ada stok)',
                          prefixIcon: Icon(AppIcons.inventory),
                          suffixText: _unitController.text.isEmpty ? 'pcs' : _unitController.text,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Masukkan jumlah stok yang valid (>= 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jumlah awal akan dicatat sebagai Stok Masuk. Kosongkan atau isi 0 jika belum ada stok fisik.',
                        style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Pengadaan',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        style: textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
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
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderStrong, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(AppIcons.calendar, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jatuh Tempo: ${DateFormat('dd/MM/yyyy').format(_dueDate)}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                Icon(AppIcons.caretDown, color: AppColors.inkMuted, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderStrong, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.warning, size: 18, color: AppColors.inkMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stok tidak diubah di sini. Gunakan menu Stok Masuk / Koreksi Stok di detail suku cadang.',
                          style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  icon: Icon(AppIcons.check, size: 18),
                  onPressed: saving ? null : _submit,
                  label: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Suku Cadang'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: saving ? null : () => context.pop(),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
