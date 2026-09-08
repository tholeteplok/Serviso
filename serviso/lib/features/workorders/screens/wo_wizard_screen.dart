import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadow.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_terms.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_progress_bar.dart';
import '../../../core/widgets/neo_search_bar.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/plate_chip.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../../auth/models/profile.dart';
import '../../customers/controllers/customer_providers.dart';
import '../../customers/controllers/validators.dart';
import '../../customers/models/customer.dart';
import '../../customers/models/vehicle.dart';
import '../../inventori/controllers/part_providers.dart';
import '../../inventori/models/part.dart';
import '../../laporan/controllers/report_controllers.dart';
import '../../settings/data/settings_repository.dart';
import '../controllers/work_order_providers.dart';
import '../logic/wo_validators.dart';
import '../models/work_order.dart';
import '../pdf/spk_actions.dart';
import '../widgets/service_picker_modal.dart';

class WoWizardScreen extends ConsumerStatefulWidget {
  const WoWizardScreen({super.key, this.initialVehicle});

  final Vehicle? initialVehicle;

  @override
  ConsumerState<WoWizardScreen> createState() => _WoWizardScreenState();
}

class _WoWizardScreenState extends ConsumerState<WoWizardScreen> {
  int _step = 0;
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];

  Vehicle? _vehicle;
  final _searchController = TextEditingController();
  List<Vehicle> _vehicleResults = [];

  bool _useManual = false;
  bool _userToggledManual = false;
  final _serviceLabelController = TextEditingController();
  Customer? _selectedCustomer;
  final _customerSearchController = TextEditingController();
  List<Customer> _customerResults = [];
  Timer? _customerSearchDebounce;

  final _complaintController = TextEditingController();
  final _odometerController = TextEditingController();
  Profile? _technician;

  final _jasaDesc = <TextEditingController>[];
  final _jasaPrice = <TextEditingController>[];
  final _partLines = <_PartLine>[];

  bool _creating = false;
  Timer? _vehicleSearchDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null) {
      _vehicle = widget.initialVehicle;
    } else {
      final terms = ref.read(appTermsProvider);
      _useManual = !terms.primaryPathIsVehicle;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serviceLabelController.dispose();
    _customerSearchController.dispose();
    _customerSearchDebounce?.cancel();
    _complaintController.dispose();
    _odometerController.dispose();
    _vehicleSearchDebounce?.cancel();
    for (final c in _jasaDesc) {
      c.dispose();
    }
    for (final c in _jasaPrice) {
      c.dispose();
    }
    for (final p in _partLines) {
      p.qtyController.dispose();
      p.priceController.dispose();
    }
    super.dispose();
  }

  Future<void> _searchVehicles(String query) async {
    _vehicleSearchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _vehicleResults = []);
      return;
    }
    _vehicleSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await ref
            .read(vehicleRepositoryProvider)
            .searchVehicles(query, limit: 20);
        if (mounted) setState(() => _vehicleResults = results);
      } catch (_) {
        if (mounted) setState(() => _vehicleResults = []);
      }
    });
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _vehicle = vehicle;
      _vehicleResults = [];
      _searchController.clear();
    });
  }

  Future<void> _searchCustomers(String query) async {
    _customerSearchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _customerResults = []);
      return;
    }
    _customerSearchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await ref
            .read(customerRepositoryProvider)
            .search(query, limit: 10);
        if (mounted) setState(() => _customerResults = results);
      } catch (_) {
        if (mounted) setState(() => _customerResults = []);
      }
    });
  }

  Future<void> _createOnlyCustomer() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showNeoBottomSheet<Customer>(
      context: context,
      title: 'Pelanggan Baru',
      child: StatefulBuilder(
        builder: (sheetCtx, _) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeoTextField(
                  controller: nameController,
                  labelText: 'Nama pelanggan *',
                  prefixIcon: AppIcons.user,
                  validator: validateCustomerName,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  controller: phoneController,
                  labelText: 'Telepon (opsional)',
                  prefixIcon: AppIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: validateCustomerPhone,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ThickBottomBorderButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final customerRepo = ref.read(customerRepositoryProvider);
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(sheetCtx);
                        try {
                          final customer = await customerRepo.create(
                            CustomerInput(
                              name: nameController.text,
                              phone: phoneController.text.trim().isEmpty
                                  ? null
                                  : phoneController.text.trim(),
                            ),
                          );
                          nav.pop(customer);
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Gagal membuat pelanggan: $e')),
                          );
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCustomer = result;
        _customerResults = [];
        _customerSearchController.clear();
      });
    }
  }

  Future<void> _createCustomerAndVehicle() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final plateController = TextEditingController();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showNeoBottomSheet<Vehicle>(
      context: context,
      title: 'Pelanggan & Kendaraan Baru',
      child: StatefulBuilder(
        builder: (sheetCtx, _) {
          return SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeoTextField(
                    controller: nameController,
                    labelText: 'Nama pelanggan',
                    prefixIcon: AppIcons.user,
                    validator: validateCustomerName,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  NeoTextField(
                    controller: phoneController,
                    labelText: 'Telepon (opsional)',
                    prefixIcon: AppIcons.phone,
                    keyboardType: TextInputType.phone,
                    validator: validateCustomerPhone,
                  ),
                  const SizedBox(height: 12),
                  NeoTextField(
                    controller: plateController,
                    labelText: 'Plat nomor',
                    prefixIcon: AppIcons.car,
                    textCapitalization: TextCapitalization.characters,
                    validator: validatePlate,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: NeoTextField(
                          controller: brandController,
                          labelText: 'Merek',
                          prefixIcon: AppIcons.tag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NeoTextField(
                          controller: modelController,
                          labelText: 'Model',
                          prefixIcon: AppIcons.wrench,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      ThickBottomBorderButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final customerRepo = ref.read(customerRepositoryProvider);
                          final vehicleRepo = ref.read(vehicleRepositoryProvider);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(sheetCtx);
                          try {
                            final customer = await customerRepo.create(
                              CustomerInput(
                                name: nameController.text,
                                phone: phoneController.text.trim().isEmpty
                                    ? null
                                    : phoneController.text.trim(),
                              ),
                            );
                            final vehicle = await vehicleRepo.create(
                              VehicleInput(
                                customerId: customer.id,
                                plateNo: plateController.text,
                                brand: brandController.text,
                                model: modelController.text,
                              ),
                            );
                            if (!mounted) return;
                            nav.pop(vehicle);
                          } catch (e) {
                            if (!mounted) return;
                            messenger
                                .showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    plateController.dispose();
    brandController.dispose();
    modelController.dispose();

    if (result != null) _selectVehicle(result);
  }

  void _addJasa({String? desc, double? price}) {
    setState(() {
      _jasaDesc.add(TextEditingController(text: desc ?? ''));
      _jasaPrice.add(TextEditingController(
        text: (price != null && price > 0) ? price.toStringAsFixed(0) : '',
      ));
    });
  }

  void _removeJasa(int index) {
    setState(() {
      _jasaDesc[index].dispose();
      _jasaPrice[index].dispose();
      _jasaDesc.removeAt(index);
      _jasaPrice.removeAt(index);
    });
  }

  void _addPart(Part part) {
    if (_partLines.any((p) => p.part.id == part.id)) return;
    setState(() {
      _partLines.add(_PartLine(part: part));
    });
  }

  void _removePart(int index) {
    setState(() {
      _partLines[index].qtyController.dispose();
      _partLines[index].priceController.dispose();
      _partLines.removeAt(index);
    });
  }

  List<WoItemInput> _buildItems() {
    final items = <WoItemInput>[];
    for (var i = 0; i < _jasaDesc.length; i++) {
      if (_jasaDesc[i].text.trim().isEmpty) continue;
      items.add(WoItemInput(
        kind: WoItemKind.jasa,
        description: _jasaDesc[i].text.trim(),
        qty: 1,
        unitPrice: double.tryParse(_jasaPrice[i].text) ?? 0,
      ));
    }
    for (final line in _partLines) {
      items.add(WoItemInput(
        kind: WoItemKind.part,
        partId: line.part.id,
        partName: line.part.name,
        description: line.part.name,
        qty: double.tryParse(line.qtyController.text) ?? 0,
        unitPrice: double.tryParse(line.priceController.text) ?? line.part.sellPrice,
      ));
    }
    return items;
  }

  String? _validateItems() {
    if (_complaintController.text.trim().isEmpty) {
      return 'Keluhan wajib diisi';
    }
    for (final line in _partLines) {
      final qty = double.tryParse(line.qtyController.text) ?? 0;
      if (qty <= 0) return 'Jumlah barang harus lebih dari 0';
    }
    for (var i = 0; i < _jasaDesc.length; i++) {
      if (_jasaDesc[i].text.trim().isEmpty) continue;
      final price = double.tryParse(_jasaPrice[i].text) ?? 0;
      if (price <= 0) return 'Harga jasa harus lebih dari 0';
    }
    return null;
  }

  double _liveTotal() {
    double total = 0;
    for (var i = 0; i < _jasaDesc.length; i++) {
      final desc = _jasaDesc[i].text.trim();
      final price = double.tryParse(_jasaPrice[i].text) ?? 0;
      if (desc.isNotEmpty) total += price;
    }
    for (final line in _partLines) {
      final qty = double.tryParse(line.qtyController.text) ?? 0;
      final price = double.tryParse(line.priceController.text) ?? line.part.sellPrice;
      total += qty * price;
    }
    return total;
  }

  Future<void> _submit() async {
    final error = _validateItems();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final hasVehicle = _vehicle != null;
    final hasManual = _useManual && _serviceLabelController.text.trim().isNotEmpty;
    if (!hasVehicle && !hasManual) {
      final terms = ref.read(appTermsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_useManual
              ? 'Masukkan nama ${terms.manualTargetLabel.toLowerCase()} terlebih dahulu'
              : (terms.businessType == 'keduanya'
                  ? 'Pilih kendaraan dulu'
                  : 'Pilih data terdaftar dulu')),
        ),
      );
      return;
    }
    if (hasManual && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih atau tambah data pelanggan dulu — diperlukan untuk nota dan riwayat.'),
        ),
      );
      return;
    }
    setState(() => _creating = true);
    final terms = ref.read(appTermsProvider);
    try {
      final draft = WorkOrderDraft(
        vehicleId: _useManual ? null : _vehicle?.id,
        serviceLabel: _useManual ? _serviceLabelController.text.trim() : null,
        customerId: _useManual ? _selectedCustomer?.id : _vehicle?.customerId,
        assignedTo: _technician?.id,
        complaint: _complaintController.text.trim(),
        odometerIn: (_useManual || !terms.hasOdometer)
            ? null
            : int.tryParse(_odometerController.text.trim()),
        items: _buildItems(),
      );
      final createdOrder = await ref.read(workOrderRepositoryProvider).create(draft);
      ref.invalidate(boardControllerProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(laporanDailySummariesProvider);
      if (!mounted) return;
      setState(() => _creating = false);
      final session = ref.read(sessionProvider).valueOrNull;
      final settings = ref.read(settingsProvider).valueOrNull;
      final customerPhone = _useManual
          ? _selectedCustomer?.phone
          : null; // jalur kendaraan: telepon pelanggan tidak selalu ter-load di step ini
      await showSpkPrompt(
        context: context,
        input: buildSpkInputFromWorkOrder(
          order: createdOrder,
          shopName: settings?.shopName.isNotEmpty == true
              ? settings!.shopName
              : (session?.shopName ?? 'Toko'),
          shopAddress: settings?.address,
          shopPhone: settings?.phone,
          customerPhone: customerPhone,
          targetLabel: terms.targetLabel,
          complaintLabel: terms.complaintLabel,
          technicianName: _technician?.fullName,
          printedBy: session?.fullName ?? '-',
        ),
      );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppTerms>(appTermsProvider, (previous, next) {
      if (!_userToggledManual && widget.initialVehicle == null) {
        setState(() {
          _useManual = !next.primaryPathIsVehicle;
        });
      }
    });

    return PopScope(
      canPop: !_creating,
      child: Scaffold(
        appBar: NeoAppBar(
          title: 'Work Order Baru',
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: NeoProgressBar(
                value: (_step + 1) / 3,
                isLoading: _creating,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _step,
              children: [
                Form(
                  key: _formKeys[0],
                  child: _StepVehicle(
                    useManual: _useManual,
                    onToggleManual: (v) => setState(() {
                      _userToggledManual = true;
                      _useManual = v;
                    }),
                    serviceLabelController: _serviceLabelController,
                    selectedCustomer: _selectedCustomer,
                    customerSearchController: _customerSearchController,
                    customerResults: _customerResults,
                    onSearchCustomer: _searchCustomers,
                    onSelectCustomer: (c) => setState(() {
                      _selectedCustomer = c;
                      _customerResults = [];
                      _customerSearchController.clear();
                    }),
                    onCreateCustomer: _createOnlyCustomer,
                    searchController: _searchController,
                    results: _vehicleResults,
                    selected: _vehicle,
                    onSearch: _searchVehicles,
                    onSelect: _selectVehicle,
                    onCreateNew: _createCustomerAndVehicle,
                    terms: ref.watch(appTermsProvider),
                  ),
                ),
                Form(
                  key: _formKeys[1],
                  child: _StepDetail(
                    complaintController: _complaintController,
                    odometerController: _odometerController,
                    technician: _technician,
                    ref: ref,
                    onTechnicianChanged: (p) => setState(() => _technician = p),
                    terms: ref.watch(appTermsProvider),
                    showOdometer: !_useManual && ref.watch(appTermsProvider).hasOdometer,
                  ),
                ),
                Form(
                  key: _formKeys[2],
                  child: _StepItems(
                    jasaDesc: _jasaDesc,
                    jasaPrice: _jasaPrice,
                    partLines: _partLines,
                    onAddJasa: _addJasa,
                    onRemoveJasa: _removeJasa,
                    onAddPart: _addPart,
                    onRemovePart: _removePart,
                    onItemsChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
            if (_creating)
              Positioned.fill(
                child: Container(
                  color: const Color(0x73111111),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: AppRadius.modal,
                        border: Border.all(color: AppColors.borderInk, width: 1.5),
                        boxShadow: AppShadow.l2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Membuat Work Order...',
                            style: AppTypography.textTheme().titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Menyimpan order & item',
                            style: AppTypography.textTheme().bodySmall?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      bottomNavigationBar: _BottomBar(
        step: _step,
        creating: _creating,
        total: _liveTotal(),
        onBack: () => setState(() => _step = (_step - 1).clamp(0, 2)),
        onNext: () {
          if (_step == 0) {
            final hasVehicle = _vehicle != null;
            final hasManual = _useManual && _serviceLabelController.text.trim().isNotEmpty;
            if (!hasVehicle && !hasManual) {
              final terms = ref.read(appTermsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_useManual
                      ? 'Masukkan nama ${terms.manualTargetLabel.toLowerCase()} terlebih dahulu'
                      : (terms.businessType == 'keduanya'
                          ? 'Pilih atau buat kendaraan dulu'
                          : 'Pilih data terdaftar dulu')),
                ),
              );
              return;
            }
            setState(() => _step = 1);
            return;
          }

          if (_step == 1) {
            if (!(_formKeys[1].currentState?.validate() ?? false)) return;
            setState(() => _step = 2);
            return;
          }

          if (_step == 2) {
            if (!(_formKeys[2].currentState?.validate() ?? false)) return;
            _submit();
          }
        },
      ),
      ),
    );
  }
}

class _PartLine {
  _PartLine({required this.part})
      : qtyController = TextEditingController(text: '1'),
        priceController = TextEditingController(
          text: part.sellPrice.toStringAsFixed(0),
        );

  final Part part;
  final TextEditingController qtyController;
  final TextEditingController priceController;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.creating,
    required this.total,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool creating;
  final double total;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            if (step > 0)
              TextButton(onPressed: onBack, child: const Text('Kembali')),
            const Spacer(),
            if (step == 2)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: textTheme.labelSmall),
                    Text(
                      rupiah(total),
                      style: AppTypography.mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            FilledButton(
              onPressed: creating ? null : onNext,
              child: creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(step < 2 ? 'Lanjut' : 'Buat Work Order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepVehicle extends StatelessWidget {
  const _StepVehicle({
    required this.useManual,
    required this.onToggleManual,
    required this.serviceLabelController,
    required this.selectedCustomer,
    required this.customerSearchController,
    required this.customerResults,
    required this.onSearchCustomer,
    required this.onSelectCustomer,
    required this.onCreateCustomer,
    required this.searchController,
    required this.results,
    required this.selected,
    required this.onSearch,
    required this.onSelect,
    required this.onCreateNew,
    required this.terms,
  });

  final bool useManual;
  final ValueChanged<bool> onToggleManual;
  final TextEditingController serviceLabelController;
  final Customer? selectedCustomer;
  final TextEditingController customerSearchController;
  final List<Customer> customerResults;
  final Future<void> Function(String) onSearchCustomer;
  final void Function(Customer) onSelectCustomer;
  final Future<void> Function() onCreateCustomer;

  final TextEditingController searchController;
  final List<Vehicle> results;
  final Vehicle? selected;
  final Future<void> Function(String) onSearch;
  final void Function(Vehicle) onSelect;
  final Future<void> Function() onCreateNew;
  final AppTerms terms;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          useManual
              ? (terms.businessType == 'keduanya'
                  ? 'Input Servis Non-Kendaraan'
                  : 'Input ${terms.manualTargetLabel}')
              : (terms.businessType == 'keduanya'
                  ? 'Pilih kendaraan'
                  : 'Pilih ${terms.targetLabel.toLowerCase()}'),
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (!useManual) ...[
          NeoSearchBar(
            controller: searchController,
            hintText: 'Cari plat atau nama pelanggan',
            onChanged: onSearch,
          ),
          const SizedBox(height: 12),
          if (results.isNotEmpty)
            ...results.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NeoCard.pressable(
                  onTap: () => onSelect(v),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      PlateChip(plateText: v.plateNo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          v.brand != null
                              ? '${v.brand} ${v.model ?? ''}'.trim()
                              : 'Kendaraan',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ThickBottomBorderButton(
            variant: ThickButtonVariant.secondary,
            icon: Icon(AppIcons.add, size: 16),
            onPressed: onCreateNew,
            isFullWidth: true,
            child: Text(terms.businessType == 'keduanya'
                ? 'Buat pelanggan & kendaraan baru'
                : 'Buat pelanggan baru'),
          ),
          if (selected != null) ...[
            const SizedBox(height: 20),
            Text('Terpilih', style: textTheme.labelMedium),
            const SizedBox(height: 8),
            NeoCard.info(
              color: AppColors.pastelMint,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  PlateChip(plateText: selected!.plateNo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selected!.brand != null
                          ? '${selected!.brand} ${selected!.model ?? ''}'.trim()
                          : 'Kendaraan',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          NeoTextField(
            controller: serviceLabelController,
            labelText: '${terms.manualTargetLabel} *',
            hintText: terms.manualTargetHint,
            prefixIcon: AppIcons.tag,
          ),
          const SizedBox(height: 16),
          Text(
            'Pelanggan *',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Wajib diisi — dipakai untuk nota, riwayat, dan notifikasi ke pelanggan.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          NeoSearchBar(
            controller: customerSearchController,
            hintText: 'Cari nama atau telepon pelanggan',
            onChanged: onSearchCustomer,
          ),
          const SizedBox(height: 8),
          if (customerResults.isNotEmpty)
            ...customerResults.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NeoCard.pressable(
                  onTap: () => onSelectCustomer(c),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(AppIcons.user, size: 18, color: AppColors.inkMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (c.phone != null && c.phone!.isNotEmpty)
                              Text(
                                c.phone!,
                                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          ThickBottomBorderButton(
            variant: ThickButtonVariant.secondary,
            icon: Icon(AppIcons.add, size: 16),
            onPressed: onCreateCustomer,
            isFullWidth: true,
            child: const Text('Buat Pelanggan Baru'),
          ),
          if (selectedCustomer != null) ...[
            const SizedBox(height: 16),
            Text('Pelanggan Terpilih', style: textTheme.labelMedium),
            const SizedBox(height: 8),
            NeoCard.info(
              color: AppColors.pastelMint,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(AppIcons.user, size: 20, color: AppColors.ink900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${selectedCustomer!.name}${selectedCustomer!.phone != null ? ' (${selectedCustomer!.phone})' : ''}',
                      style: textTheme.titleSmall?.copyWith(
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
        if (terms.alternatePathLinkLabel != null) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => onToggleManual(!useManual),
              child: Text(
                useManual
                    ? '+ Ada data kendaraan terdaftar?'
                    : '+ Servis tanpa kendaraan terdaftar',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepDetail extends StatelessWidget {
  const _StepDetail({
    required this.complaintController,
    required this.odometerController,
    required this.technician,
    required this.ref,
    required this.onTechnicianChanged,
    required this.terms,
    this.showOdometer = true,
  });

  final TextEditingController complaintController;
  final TextEditingController odometerController;
  final Profile? technician;
  final WidgetRef ref;
  final void Function(Profile?) onTechnicianChanged;
  final AppTerms terms;
  final bool showOdometer;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final techniciansAsync = ref.watch(techniciansProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Detail work order', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        NeoTextField(
          controller: complaintController,
          labelText: terms.complaintLabel,
          hintText: terms.complaintHint,
          prefixIcon: AppIcons.alertCircle,
          maxLines: 3,
          validator: WoValidators.validateComplaint,
        ),
        if (showOdometer) ...[
          const SizedBox(height: 12),
          NeoTextField(
            controller: odometerController,
            labelText: 'Odometer masuk (KM, opsional)',
            prefixIcon: AppIcons.speedometer,
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 12),
        techniciansAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const SizedBox.shrink(),
          data: (technicians) => DropdownButtonFormField<Profile?>(
            // ignore: deprecated_member_use
            value: technician,
            decoration: InputDecoration(
              labelText: 'Teknisi (opsional)',
              prefixIcon: Icon(AppIcons.user),
            ),
            items: [
              const DropdownMenuItem<Profile?>(
                value: null,
                child: Text('Belum ditentukan'),
              ),
              for (final t in technicians)
                DropdownMenuItem<Profile?>(
                  value: t,
                  child: Text(t.fullName),
                ),
            ],
            onChanged: onTechnicianChanged,
          ),
        ),
      ],
    );
  }
}

class _StepItems extends ConsumerWidget {
  const _StepItems({
    required this.jasaDesc,
    required this.jasaPrice,
    required this.partLines,
    required this.onAddJasa,
    required this.onRemoveJasa,
    required this.onAddPart,
    required this.onRemovePart,
    required this.onItemsChanged,
  });

  final List<TextEditingController> jasaDesc;
  final List<TextEditingController> jasaPrice;
  final List<_PartLine> partLines;
  final void Function({String? desc, double? price}) onAddJasa;
  final void Function(int) onRemoveJasa;
  final void Function(Part) onAddPart;
  final void Function(int) onRemovePart;
  final VoidCallback onItemsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Item work order', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text('Jasa', style: textTheme.titleMedium)),
            ThickBottomBorderButton(
              variant: ThickButtonVariant.secondary,
              size: ThickButtonSize.compact,
              icon: Icon(AppIcons.search, size: 14),
              onPressed: () async {
                final service = await showServicePicker(context, ref);
                if (service != null) {
                  onAddJasa(desc: service.name, price: service.price);
                  onItemsChanged();
                }
              },
              child: const Text('Pilih jasa'),
            ),
            const SizedBox(width: 8),
            ThickBottomBorderButton(
              variant: ThickButtonVariant.secondary,
              size: ThickButtonSize.compact,
              icon: Icon(AppIcons.add, size: 14),
              onPressed: () {
                onAddJasa();
                onItemsChanged();
              },
              child: const Text('Tulis manual'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < jasaDesc.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NeoCard.info(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: NeoTextField(
                      controller: jasaDesc[i],
                      labelText: 'Deskripsi jasa',
                      isDense: true,
                      onChanged: (_) => onItemsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: NeoTextField(
                      controller: jasaPrice[i],
                      labelText: 'Harga',
                      prefixText: 'Rp ',
                      isDense: true,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onItemsChanged(),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemoveJasa(i),
                    icon: Icon(AppIcons.trash, color: AppColors.statusDanger),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Barang', style: textTheme.titleMedium)),
            ThickBottomBorderButton(
              variant: ThickButtonVariant.secondary,
              size: ThickButtonSize.compact,
              onPressed: () async {
                final code = await showBarcodeScanner(context);
                if (code != null && code.isNotEmpty) {
                  final list = await ref.read(partRepositoryProvider).list(search: code, limit: 10);
                  if (list.isNotEmpty) {
                    onAddPart(list.first);
                    onItemsChanged();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Barang dengan barcode "$code" tidak ditemukan')),
                    );
                  }
                }
              },
              child: Icon(AppIcons.barcode, size: 16),
            ),
            const SizedBox(width: 8),
            ThickBottomBorderButton(
              variant: ThickButtonVariant.secondary,
              size: ThickButtonSize.compact,
              icon: Icon(AppIcons.add, size: 14),
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (sheetContext) => _PartPickerSheet(
                    onAddPart: onAddPart,
                  ),
                );
                onItemsChanged();
              },
              child: const Text('Pilih barang'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < partLines.length; i++)
          _PartLineTile(
            line: partLines[i],
            onRemove: () => onRemovePart(i),
            onItemsChanged: onItemsChanged,
          ),
      ],
    );
  }
}

class _PartLineTile extends StatelessWidget {
  const _PartLineTile({
    required this.line,
    required this.onRemove,
    required this.onItemsChanged,
  });

  final _PartLine line;
  final VoidCallback onRemove;
  final VoidCallback onItemsChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final qty = double.tryParse(line.qtyController.text) ?? 0;
    final overStock = qty > line.part.stockQty;
    return NeoCard.info(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(line.part.name, style: textTheme.titleMedium)),
              IconButton(
                onPressed: onRemove,
                icon: Icon(AppIcons.trash, color: AppColors.statusDanger),
              ),
            ],
          ),
          Text(
            'Stok tersedia: ${line.part.stockQty.toStringAsFixed(0)}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: NeoTextField(
                  controller: line.qtyController,
                  labelText: 'Jumlah',
                  isDense: true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onItemsChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoTextField(
                  controller: line.priceController,
                  labelText: 'Harga / unit',
                  isDense: true,
                  prefixText: 'Rp ',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onItemsChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Stok dikurangi saat diselesaikan.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (overStock)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Jumlah melebihi stok tersedia. Akan divalidasi saat diselesaikan.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.statusDanger),
              ),
            ),
        ],
      ),
    );
  }
}

class _PartPickerSheet extends ConsumerStatefulWidget {
  const _PartPickerSheet({
    required this.onAddPart,
  });

  final void Function(Part) onAddPart;

  @override
  ConsumerState<_PartPickerSheet> createState() => _PartPickerSheetState();
}

class _PartPickerSheetState extends ConsumerState<_PartPickerSheet> {
  final _controller = TextEditingController();
  List<Part> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch(String query) async {
    setState(() => _loading = true);
    try {
      final list = await ref.read(partRepositoryProvider).list(
            search: query.trim().isEmpty ? null : query.trim(),
            limit: 30,
          );
      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih barang', style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Cari nama atau kode',
                prefixIcon: Icon(AppIcons.search),
                suffixIcon: IconButton(
                  icon: Icon(AppIcons.barcode),
                  tooltip: 'Scan Barcode',
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final code = await showBarcodeScanner(context);
                    if (code != null && code.isNotEmpty) {
                      _controller.text = code;
                      await _fetch(code);
                      if (_results.length == 1 && mounted) {
                        widget.onAddPart(_results.first);
                        nav.pop();
                      }
                    }
                  },
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(value));
              },
              autofocus: true,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_results.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Tidak ada barang ditemukan.'),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.name),
                      subtitle: Text(
                        'Stok: ${p.stockQty.toStringAsFixed(0)} · ${rupiah(p.sellPrice)}',
                      ),
                      trailing: Icon(AppIcons.add, color: AppColors.primary),
                      onTap: () {
                        widget.onAddPart(p);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
