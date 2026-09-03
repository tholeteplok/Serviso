import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../controllers/customer_form_controller.dart';
import '../controllers/customer_list_controller.dart';
import '../controllers/validators.dart';
import '../models/customer.dart';

void showCustomerForm(
  BuildContext context,
  WidgetRef ref,
  Customer? initial, {
  VoidCallback? onSaved,
}) {
  showNeoBottomSheet(
    context: context,
    title: initial != null ? 'Ubah Pelanggan' : 'Tambah Pelanggan',
    child: CustomerFormSheet(
      initial: initial,
      onSaved: onSaved,
    ),
  );
}

class CustomerFormSheet extends ConsumerStatefulWidget {
  const CustomerFormSheet({
    super.key,
    this.initial,
    this.onSaved,
  });

  final Customer? initial;
  final VoidCallback? onSaved;

  @override
  ConsumerState<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.initial?.phone ?? '',
    );
    _addressController =
        TextEditingController(text: widget.initial?.address ?? '');
    _noteController = TextEditingController(text: widget.initial?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller =
        ref.read(customerFormControllerProvider(widget.initial).notifier);
    try {
      await controller.submit(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved?.call();
      ref.invalidate(customerListControllerProvider);
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
    final state = ref.watch(customerFormControllerProvider(widget.initial));
    final saving = state.isLoading;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeoTextField(
              controller: _nameController,
              labelText: 'Nama',
              prefixIcon: AppIcons.user,
              textInputAction: TextInputAction.next,
              validator: validateCustomerName,
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: _phoneController,
              labelText: 'Telepon (opsional)',
              prefixIcon: AppIcons.phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: validateCustomerPhone,
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: _addressController,
              labelText: 'Alamat (opsional)',
              prefixIcon: AppIcons.home,
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: _noteController,
              labelText: 'Catatan (opsional)',
              prefixIcon: AppIcons.notepad,
              maxLines: 3,
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
