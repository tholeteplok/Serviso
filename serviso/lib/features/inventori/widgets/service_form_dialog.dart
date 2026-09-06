import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../controllers/service_providers.dart';
import '../models/service_item.dart';

Future<ServiceItem?> showServiceFormDialog(
  BuildContext context,
  WidgetRef ref, {
  ServiceItem? initialService,
}) async {
  final isEdit = initialService != null;
  final nameController = TextEditingController(text: initialService?.name ?? '');
  final codeController = TextEditingController(text: initialService?.code ?? '');
  final priceController = TextEditingController(
    text: initialService != null && initialService.price > 0
        ? initialService.price.toStringAsFixed(0)
        : '',
  );
  final descController =
      TextEditingController(text: initialService?.description ?? '');
  final formKey = GlobalKey<FormState>();
  var saving = false;

  return showNeoBottomSheet<ServiceItem>(
    context: context,
    title: isEdit ? 'Ubah Jasa' : 'Tambah Jasa Baru',
    child: StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoTextField(
                  key: const Key('service_name_field'),
                  controller: nameController,
                  labelText: 'Nama Layanan / Jasa *',
                  hintText: 'mis. Ganti Oli, Servis Karburator, Cuci AC',
                  prefixIcon: AppIcons.wrench,
                  autofocus: !isEdit,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama layanan / jasa wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('service_price_field'),
                  controller: priceController,
                  labelText: 'Tarif Standar (Harga) *',
                  hintText: '0',
                  prefixText: 'Rp ',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    final p = double.tryParse(val?.trim() ?? '');
                    if (p == null || p < 0) {
                      return 'Tarif harus berupa nominal valid (>= 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('service_code_field'),
                  controller: codeController,
                  labelText: 'Kode Jasa (opsional)',
                  hintText: 'mis. JS-01, OLI-SVC',
                  prefixIcon: AppIcons.tag,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('service_desc_field'),
                  controller: descController,
                  labelText: 'Keterangan (opsional)',
                  hintText: 'Catatan pengerjaan atau detail layanan',
                  prefixIcon: AppIcons.notepad,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ThickBottomBorderButton(
                        variant: ThickButtonVariant.secondary,
                        onPressed: saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ThickBottomBorderButton(
                        key: const Key('submit_service_button'),
                        variant: ThickButtonVariant.primary,
                        isLoading: saving,
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setState(() => saving = true);

                                try {
                                  final input = ServiceInput(
                                    name: nameController.text.trim(),
                                    code: codeController.text.trim().isEmpty
                                        ? null
                                        : codeController.text.trim(),
                                    price: double.tryParse(
                                            priceController.text.trim()) ??
                                        0,
                                    description: descController.text.trim().isEmpty
                                        ? null
                                        : descController.text.trim(),
                                  );

                                  final controller = ref
                                      .read(serviceListControllerProvider.notifier);
                                  final result = isEdit
                                      ? await controller.updateService(
                                          initialService.id, input)
                                      : await controller.createService(input);

                                  if (context.mounted) {
                                    Navigator.of(context).pop(result);
                                  }
                                } catch (e) {
                                  setState(() => saving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.statusDanger,
                                        content: Text('Gagal menyimpan jasa: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Jasa'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ),
  );
}
