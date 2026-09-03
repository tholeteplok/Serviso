import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../controllers/vehicle_form_controller.dart';
import '../controllers/validators.dart';
import '../models/vehicle.dart';

void showVehicleForm({
  required BuildContext context,
  required WidgetRef ref,
  required String customerId,
  Vehicle? initial,
  VoidCallback? onSaved,
}) {
  showNeoBottomSheet(
    context: context,
    title: initial != null ? 'Ubah Kendaraan' : 'Tambah Kendaraan',
    child: VehicleFormSheet(
      customerId: customerId,
      initial: initial,
      onSaved: onSaved,
    ),
  );
}

class VehicleFormSheet extends ConsumerStatefulWidget {
  const VehicleFormSheet({
    super.key,
    required this.customerId,
    this.initial,
    this.onSaved,
  });

  final String customerId;
  final Vehicle? initial;
  final VoidCallback? onSaved;

  @override
  ConsumerState<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends ConsumerState<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    _plateController =
        TextEditingController(text: widget.initial?.plateNo ?? '');
    _brandController = TextEditingController(text: widget.initial?.brand ?? '');
    _modelController = TextEditingController(text: widget.initial?.model ?? '');
    _yearController =
        TextEditingController(text: widget.initial?.year?.toString() ?? '');
    _colorController = TextEditingController(text: widget.initial?.color ?? '');
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final yearText = _yearController.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);
    final controller = ref.read(
      vehicleFormControllerProvider(
        VehicleFormArgs(
          customerId: widget.customerId,
          initial: widget.initial,
        ),
      ).notifier,
    );
    try {
      await controller.submit(
        plateNo: _plateController.text,
        brand: _brandController.text,
        model: _modelController.text,
        year: year,
        color: _colorController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
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
    final isEdit = widget.initial != null;
    final state = ref.watch(
      vehicleFormControllerProvider(
        VehicleFormArgs(
          customerId: widget.customerId,
          initial: widget.initial,
        ),
      ),
    );
    final saving = state.isLoading;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeoTextField(
              controller: _plateController,
              labelText: 'Plat nomor',
              prefixIcon: AppIcons.car,
              hintText: 'B 1234 ABC',
              textCapitalization: TextCapitalization.characters,
              validator: validatePlate,
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: _brandController,
              labelText: 'Merek (opsional)',
              prefixIcon: AppIcons.tag,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: _modelController,
              labelText: 'Model (opsional)',
              prefixIcon: AppIcons.wrench,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NeoTextField(
                    controller: _yearController,
                    labelText: 'Tahun (opsional)',
                    prefixIcon: AppIcons.calendar,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeoTextField(
                    controller: _colorController,
                    labelText: 'Warna (opsional)',
                    prefixIcon: AppIcons.tag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ThickBottomBorderButton(
              isFullWidth: true,
              onPressed: saving ? null : _submit,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}
