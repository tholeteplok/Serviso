import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/plate_chip.dart';
import '../../auth/models/profile.dart';
import '../../customers/controllers/customer_providers.dart';
import '../../customers/controllers/validators.dart';
import '../../customers/models/customer.dart';
import '../../customers/models/vehicle.dart';
import '../../inventori/controllers/part_providers.dart';
import '../../inventori/models/part.dart';
import '../controllers/work_order_providers.dart';
import '../logic/wo_validators.dart';
import '../models/work_order.dart';

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

  final _complaintController = TextEditingController();
  final _odometerController = TextEditingController();
  Profile? _technician;

  final _jasaDesc = <TextEditingController>[];
  final _jasaPrice = <TextEditingController>[];
  final _partLines = <_PartLine>[];

  bool _creating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null) {
      _vehicle = widget.initialVehicle;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _complaintController.dispose();
    _odometerController.dispose();
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
    if (query.trim().isEmpty) {
      setState(() => _vehicleResults = []);
      return;
    }
    try {
      final results = await ref
          .read(vehicleRepositoryProvider)
          .searchVehicles(query, limit: 20);
      if (mounted) setState(() => _vehicleResults = results);
    } catch (_) {
      if (mounted) setState(() => _vehicleResults = []);
    }
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _vehicle = vehicle;
      _vehicleResults = [];
      _searchController.clear();
    });
  }

  Future<void> _createCustomerAndVehicle() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final plateController = TextEditingController();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Vehicle>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pelanggan & Kendaraan Baru'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama pelanggan'),
                  validator: validateCustomerName,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telepon (opsional)'),
                  keyboardType: TextInputType.phone,
                  validator: validateCustomerPhone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: plateController,
                  decoration: const InputDecoration(labelText: 'Plat nomor'),
                  textCapitalization: TextCapitalization.characters,
                  validator: validatePlate,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Merek'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(labelText: 'Model'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final customerRepo = ref.read(customerRepositoryProvider);
              final vehicleRepo = ref.read(vehicleRepositoryProvider);
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(dialogContext);
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
    );

    nameController.dispose();
    phoneController.dispose();
    plateController.dispose();
    brandController.dispose();
    modelController.dispose();

    if (result != null) _selectVehicle(result);
  }

  void _addJasa() {
    setState(() {
      _jasaDesc.add(TextEditingController());
      _jasaPrice.add(TextEditingController());
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

  Future<void> _searchParts(String query, StateSetter setSheet) async {
    final parts = await ref.read(partRepositoryProvider).list(
          search: query.isEmpty ? null : query,
          limit: 20,
        );
    setSheet(() => _partSearchResults = parts);
  }

  List<Part> _partSearchResults = [];

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
      final desc = _jasaDesc[i].text.trim();
      final price = double.tryParse(_jasaPrice[i].text) ?? 0;
      if (desc.isNotEmpty) {
        items.add(WoItemInput(
          kind: WoItemKind.jasa,
          description: desc,
          qty: 1,
          unitPrice: price,
        ));
      }
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
      if (qty <= 0) return 'Jumlah part harus lebih dari 0';
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
    if (_vehicle == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih kendaraan dulu')));
      return;
    }
    setState(() => _creating = true);
    try {
      final draft = WorkOrderDraft(
        vehicleId: _vehicle!.id,
        assignedTo: _technician?.id,
        complaint: _complaintController.text,
        odometerIn: int.tryParse(_odometerController.text.trim()),
        items: _buildItems(),
      );
      await ref.read(workOrderRepositoryProvider).create(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Work order dibuat')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Baru'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: AppColors.line,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKeys[_step],
        child: IndexedStack(
          index: _step,
          children: [
            _StepVehicle(
              searchController: _searchController,
              results: _vehicleResults,
              selected: _vehicle,
              onSearch: _searchVehicles,
              onSelect: _selectVehicle,
              onCreateNew: _createCustomerAndVehicle,
            ),
            _StepDetail(
              complaintController: _complaintController,
              odometerController: _odometerController,
              technician: _technician,
              ref: ref,
              onTechnicianChanged: (p) => setState(() => _technician = p),
            ),
            _StepItems(
              jasaDesc: _jasaDesc,
              jasaPrice: _jasaPrice,
              partLines: _partLines,
              onAddJasa: _addJasa,
              onRemoveJasa: _removeJasa,
              onSearchParts: _searchParts,
              onAddPart: _addPart,
              onRemovePart: _removePart,
              partSearchResults: _partSearchResults,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        step: _step,
        creating: _creating,
        total: _liveTotal(),
        onBack: () => setState(() => _step = (_step - 1).clamp(0, 2)),
        onNext: () {
          if (!_formKeys[_step].currentState!.validate()) return;
          if (_step == 0 && _vehicle == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pilih atau buat kendaraan dulu')),
            );
            return;
          }
          if (_step < 2) {
            setState(() => _step++);
          } else {
            _submit();
          }
        },
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
    required this.searchController,
    required this.results,
    required this.selected,
    required this.onSearch,
    required this.onSelect,
    required this.onCreateNew,
  });

  final TextEditingController searchController;
  final List<Vehicle> results;
  final Vehicle? selected;
  final Future<void> Function(String) onSearch;
  final void Function(Vehicle) onSelect;
  final Future<void> Function() onCreateNew;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Pilih kendaraan',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Cari plat atau nama pelanggan',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onSearch,
        ),
        const SizedBox(height: 12),
        if (results.isNotEmpty)
          ...results.map(
            (v) => Card(
              child: ListTile(
                leading: PlateChip(plateText: v.plateNo),
                title: Text(v.brand != null
                    ? '${v.brand} ${v.model ?? ''}'.trim()
                    : 'Kendaraan'),
                onTap: () => onSelect(v),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onCreateNew,
          icon: const Icon(Icons.add),
          label: const Text('Buat pelanggan & kendaraan baru'),
        ),
        if (selected != null) ...[
          const SizedBox(height: 20),
          Text('Terpilih', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          Card(
            color: AppColors.tintOf(AppColors.teal),
            child: Padding(
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
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
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
  });

  final TextEditingController complaintController;
  final TextEditingController odometerController;
  final Profile? technician;
  final WidgetRef ref;
  final void Function(Profile?) onTechnicianChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final techniciansAsync = ref.watch(techniciansProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Detail work order', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        TextFormField(
          controller: complaintController,
          decoration: const InputDecoration(
            labelText: 'Keluhan',
            prefixIcon: Icon(Icons.report_problem_outlined),
          ),
          maxLines: 3,
          validator: WoValidators.validateComplaint,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: odometerController,
          decoration: const InputDecoration(
            labelText: 'Odometer masuk (KM, opsional)',
            prefixIcon: Icon(Icons.speed_outlined),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        techniciansAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const SizedBox.shrink(),
          data: (technicians) => DropdownButtonFormField<Profile?>(
            // ignore: deprecated_member_use
            value: technician,
            decoration: const InputDecoration(
              labelText: 'Teknisi (opsional)',
              prefixIcon: Icon(Icons.person_outline),
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

class _StepItems extends StatelessWidget {
  const _StepItems({
    required this.jasaDesc,
    required this.jasaPrice,
    required this.partLines,
    required this.onAddJasa,
    required this.onRemoveJasa,
    required this.onSearchParts,
    required this.onAddPart,
    required this.onRemovePart,
    required this.partSearchResults,
  });

  final List<TextEditingController> jasaDesc;
  final List<TextEditingController> jasaPrice;
  final List<_PartLine> partLines;
  final VoidCallback onAddJasa;
  final void Function(int) onRemoveJasa;
  final Future<void> Function(String, StateSetter) onSearchParts;
  final void Function(Part) onAddPart;
  final void Function(int) onRemovePart;
  final List<Part> partSearchResults;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Item work order', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('Jasa', style: textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: onAddJasa,
              icon: const Icon(Icons.add),
              label: const Text('Tambah jasa'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < jasaDesc.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: jasaDesc[i],
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi jasa',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: jasaPrice[i],
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemoveJasa(i),
                    icon: const Icon(Icons.delete_outline, color: AppColors.action),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Part', style: textTheme.titleMedium)),
            TextButton.icon(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (sheetContext) => _PartPickerSheet(
                    onSearch: onSearchParts,
                    results: partSearchResults,
                    onAddPart: onAddPart,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Pilih part'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < partLines.length; i++)
          _PartLineTile(
            line: partLines[i],
            onRemove: () => onRemovePart(i),
          ),
      ],
    );
  }
}

class _PartLineTile extends StatelessWidget {
  const _PartLineTile({required this.line, required this.onRemove});

  final _PartLine line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final qty = double.tryParse(line.qtyController.text) ?? 0;
    final overStock = qty > line.part.stockQty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(line.part.name, style: textTheme.titleMedium)),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: AppColors.action),
                ),
              ],
            ),
            Text(
              'Stok tersedia: ${line.part.stockQty.toStringAsFixed(0)}',
              style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: line.qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga / unit',
                      isDense: true,
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Stok dikurangi saat diselesaikan.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            if (overStock)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Jumlah melebihi stok tersedia. Akan divalidasi saat diselesaikan.',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.action),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartPickerSheet extends StatefulWidget {
  const _PartPickerSheet({
    required this.onSearch,
    required this.results,
    required this.onAddPart,
  });

  final Future<void> Function(String, StateSetter) onSearch;
  final List<Part> results;
  final void Function(Part) onAddPart;

  @override
  State<_PartPickerSheet> createState() => _PartPickerSheetState();
}

class _PartPickerSheetState extends State<_PartPickerSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.onSearch('', setState);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih part', style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Cari nama atau kode',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => widget.onSearch(value, setState),
            ),
            const SizedBox(height: 12),
            ...widget.results.map(
              (p) => ListTile(
                title: Text(p.name),
                subtitle: Text(
                  'Stok: ${p.stockQty.toStringAsFixed(0)} · ${rupiah(p.sellPrice)}',
                ),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  widget.onAddPart(p);
                  Navigator.of(context).pop();
                },
              ),
            ),
            if (widget.results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tidak ada part ditemukan.'),
              ),
          ],
        ),
      ),
    );
  }
}
