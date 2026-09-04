import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/distributor_autocomplete_field.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/neo_stepper.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_detail_controller.dart';
import '../controllers/part_form_controller.dart';
import '../controllers/part_list_controller.dart';
import '../data/repository_exception.dart';
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
  late final TextEditingController _distributorController;

  var _paymentType = 'tunai';
  late DateTime _dueDate;
  bool _loadingPart = false;
  bool _isSubmitting = false;
  Part? _resolvedInitial;
  num _quantity = 0;

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
    _distributorController = TextEditingController();
    _dueDate = DateTime.now().add(const Duration(days: 14));

    _costController.addListener(_onPriceChanged);
    _sellController.addListener(_onPriceChanged);

    if (widget.partId != null && _resolvedInitial == null) {
      _fetchPart();
    }
  }

  void _onPriceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchPart() async {
    setState(() => _loadingPart = true);
    try {
      final data =
          await ref.read(partDetailControllerProvider(widget.partId!).future);
      final part = data.part;
      if (!mounted) return;
      setState(() {
        _resolvedInitial = part;
        _nameController.text = part.name;
        _codeController.text = part.code ?? '';
        _minStockController.text = part.minStock.toString();
        _costController.text =
            part.costPrice == 0 ? '' : part.costPrice.toStringAsFixed(0);
        _sellController.text =
            part.sellPrice == 0 ? '' : part.sellPrice.toStringAsFixed(0);
        _unitController.text = part.unit ?? 'pcs';
      });
    } catch (_) {
      // keep empty for fallback
    } finally {
      if (mounted) setState(() => _loadingPart = false);
    }
  }

  @override
  void dispose() {
    _costController.removeListener(_onPriceChanged);
    _sellController.removeListener(_onPriceChanged);
    _nameController.dispose();
    _codeController.dispose();
    _minStockController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _unitController.dispose();
    _distributorController.dispose();
    super.dispose();
  }

  bool get _isEdit => _resolvedInitial != null || widget.partId != null;

  Part? get _effectiveInitial => _resolvedInitial ?? widget.initial;

  bool get _hasUnsavedChanges {
    if (_isEdit) {
      final init = _effectiveInitial;
      if (init == null) return false;
      return _nameController.text.trim() != init.name ||
          _codeController.text.trim() != (init.code ?? '') ||
          _minStockController.text.trim() != init.minStock.toString() ||
          _costController.text.trim() !=
              (init.costPrice == 0 ? '' : init.costPrice.toStringAsFixed(0)) ||
          _sellController.text.trim() !=
              (init.sellPrice == 0 ? '' : init.sellPrice.toStringAsFixed(0)) ||
          _unitController.text.trim() != (init.unit ?? 'pcs');
    } else {
      return _nameController.text.trim().isNotEmpty ||
          _costController.text.trim().isNotEmpty ||
          _sellController.text.trim().isNotEmpty ||
          _quantity > 0 ||
          _distributorController.text.trim().isNotEmpty;
    }
  }

  Future<bool> _handlePop() async {
    if (!_hasUnsavedChanges) return true;
    final confirm = await showNeoConfirmDialog(
      context: context,
      title: 'Batalkan Pengisian?',
      message: 'Data yang telah Anda masukkan belum disimpan dan akan hilang.',
      confirmLabel: 'Batalkan',
      cancelLabel: 'Lanjut Mengisi',
      isDanger: true,
    );
    return confirm ?? false;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final isAdmin = ref.read(isAdminProvider);
    final controller =
        ref.read(partFormControllerProvider(_effectiveInitial).notifier);

    final minStock = int.tryParse(_minStockController.text.trim()) ?? 0;
    final cost = isAdmin ? double.tryParse(_costController.text.trim()) : null;
    final sell = isAdmin ? double.tryParse(_sellController.text.trim()) : null;

    final isEdit = _isEdit;
    final initialStock = !isEdit ? _quantity.toDouble() : 0.0;
    final rawDistributor =
        (!isEdit && initialStock > 0) ? _distributorController.text.trim() : null;
    final distributor =
        rawDistributor?.isEmpty == true ? null : rawDistributor;
    // Kasir dilarang memilih hutang; jika bukan admin, kunci metode ke tunai
    final paymentType =
        (!isEdit && initialStock > 0 && isAdmin) ? _paymentType : 'tunai';
    final dueDate =
        (!isEdit && initialStock > 0 && paymentType == 'hutang') ? _dueDate : null;

    try {
      await controller.submit(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        unit: _unitController.text.trim(),
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
          SnackBar(
            content: Text(
              isEdit
                  ? 'Suku cadang berhasil diperbarui'
                  : 'Suku cadang berhasil ditambahkan',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.action,
          content: Text(mapRepositoryError(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final isEdit = _isEdit;
    final isAdmin = ref.watch(isAdminProvider);
    final state = ref.watch(partFormControllerProvider(_effectiveInitial));
    final saving = state.isLoading || _isSubmitting;

    if (_loadingPart) {
      return const Scaffold(
        appBar: NeoAppBar(title: 'Memuat...'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cost = double.tryParse(_costController.text.trim()) ?? 0;
    final sell = double.tryParse(_sellController.text.trim()) ?? 0;
    final hasBothPrices = cost > 0 && sell > 0;
    final profit = sell - cost;
    final marginPercent = sell > 0 ? (profit / sell) * 100 : 0.0;
    final isNegativeMargin = hasBothPrices && sell < cost;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handlePop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: NeoAppBar(
          title: isEdit ? 'Ubah Suku Cadang' : 'Tambah Suku Cadang',
          onBack: () async {
            final shouldPop = await _handlePop();
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  title: 'Informasi Dasar',
                  child: Column(
                    children: [
                      NeoTextField(
                        key: const Key('part_name_field'),
                        controller: _nameController,
                        labelText: 'Nama *',
                        hintText: 'Misal: Kampas Rem Depan Vario',
                        prefixIcon: AppIcons.tag,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama suku cadang wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      NeoTextField(
                        key: const Key('part_code_field'),
                        controller: _codeController,
                        labelText: 'Kode (Opsional)',
                        prefixIcon: AppIcons.barcode,
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
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      DropdownMenu<String>(
                        controller: _unitController,
                        width: double.infinity,
                        label: const Text('Satuan Unit'),
                        leadingIcon: Icon(AppIcons.tag),
                        enableFilter: true,
                        requestFocusOnTap: true,
                        initialSelection: _effectiveInitial?.unit ?? 'pcs',
                        onSelected: (val) {
                          if (val != null) setState(() {});
                        },
                        dropdownMenuEntries: _unitOptions
                            .map((u) => DropdownMenuEntry(value: u, label: u))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      NeoTextField(
                        key: const Key('part_min_stock_field'),
                        controller: _minStockController,
                        labelText: 'Batas Stok Menipis',
                        prefixIcon: AppIcons.warning,
                        helperText:
                            'Peringatan otomatis muncul saat stok <= nilai ini',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Masukkan angka batas stok yang valid (>= 0)';
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NeoTextField(
                          key: const Key('part_cost_field'),
                          controller: _costController,
                          labelText: 'Modal Beli (Rp)',
                          hintText: 'Misal: 45000',
                          prefixIcon: AppIcons.cart,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Masukkan modal beli yang valid (>= 0)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        NeoTextField(
                          key: const Key('part_sell_field'),
                          controller: _sellController,
                          labelText: 'Harga Jual (Rp)',
                          hintText: 'Misal: 60000',
                          prefixIcon: AppIcons.money,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Masukkan harga jual yang valid (>= 0)';
                            }
                            return null;
                          },
                        ),
                        if (hasBothPrices) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isNegativeMargin
                                  ? AppColors.pastelPink
                                  : AppColors.pastelMint,
                              borderRadius: AppRadius.button,
                              border: Border.all(
                                color: AppColors.borderInk,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isNegativeMargin
                                      ? AppIcons.warning
                                      : AppIcons.check,
                                  size: 18,
                                  color: AppColors.ink900,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isNegativeMargin
                                        ? 'Peringatan: Harga jual lebih rendah dari modal (Rugi ${rupiah(profit.abs())} / unit)'
                                        : 'Estimasi Laba: ${rupiah(profit)} / unit (Margin: ${marginPercent.toStringAsFixed(1)}%)',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      borderRadius: AppRadius.button,
                      border: Border.all(
                        color: AppColors.borderInk,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.alertCircle, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Harga diatur oleh pemilik. Suku cadang ditambahkan tanpa harga.',
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Jumlah Stok Awal',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            NeoStepper(
                              value: _quantity,
                              min: 0,
                              step: 1,
                              unit: _unitController.text.isEmpty
                                  ? 'pcs'
                                  : _unitController.text,
                              allowDecimals: true,
                              onChanged: (v) => setState(() => _quantity = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bgBase,
                            borderRadius: AppRadius.button,
                            border: Border.all(color: AppColors.borderHairline),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.inventory,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _quantity == 0
                                      ? 'Kosongkan (0) jika belum ada stok fisik. Pengadaan dapat dicatat nanti di menu Stok Masuk.'
                                      : '${_quantity.toString().replaceAll(RegExp(r'\.0$'), '')} ${_unitController.text.isEmpty ? 'pcs' : _unitController.text} akan langsung dicatat sebagai Stok Masuk.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_quantity > 0) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Pengadaan Stok Awal',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DistributorAutocompleteField(
                            key: const Key('part_distributor_field'),
                            controller: _distributorController,
                            labelText: 'Distributor / Pemasok (Opsional)',
                            hintText: 'Misal: PT Astra Otoparts',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Metode Pembayaran Pengadaan',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isAdmin) ...[
                            NeoSegmentControl<String>(
                              selectedValue: _paymentType,
                              onValueChanged: (val) =>
                                  setState(() => _paymentType = val),
                              items: [
                                NeoSegmentItem<String>(
                                  value: 'tunai',
                                  label: 'Tunai',
                                  icon: Icon(AppIcons.wallet, size: 16),
                                ),
                                NeoSegmentItem<String>(
                                  value: 'hutang',
                                  label: 'Hutang',
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
                                    initialDate: _dueDate.isBefore(DateTime.now()) ? DateTime.now() : _dueDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => _dueDate = picked);
                                  }
                                },
                                borderRadius: AppRadius.button,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.borderInk,
                                      width: 1.5,
                                    ),
                                    borderRadius: AppRadius.button,
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
                                          'Jatuh Tempo: ${DateFormat('dd/MM/yyyy').format(_dueDate)}',
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
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.pastelMint.withValues(alpha: 0.3),
                                borderRadius: AppRadius.button,
                                border: Border.all(
                                  color: AppColors.borderInk,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    AppIcons.wallet,
                                    size: 16,
                                    color: AppColors.ink900,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Metode Pembayaran: Tunai (Hutang hanya dapat dicatat oleh Admin/Pemilik)',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppRadius.button,
                      border: Border.all(
                        color: AppColors.borderInk,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.warning, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Stok tidak diubah di sini. Gunakan menu Stok Masuk / Koreksi Stok di detail suku cadang.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ThickBottomBorderButton(
                  key: const Key('submit_part_button'),
                  onPressed: saving ? null : _submit,
                  isLoading: saving,
                  isFullWidth: true,
                  variant: ThickButtonVariant.primary,
                  icon: Icon(AppIcons.check, size: 18),
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Suku Cadang',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ThickBottomBorderButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final shouldPop = await _handlePop();
                          if (shouldPop && context.mounted) {
                            context.pop();
                          }
                        },
                  isFullWidth: true,
                  variant: ThickButtonVariant.secondary,
                  child: Text(
                    'Batal',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

