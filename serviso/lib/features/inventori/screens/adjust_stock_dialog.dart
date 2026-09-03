import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_detail_controller.dart';
import '../models/part.dart';
import '../part_logic.dart';

Future<void> showAdjustStockDialog(
  BuildContext context,
  WidgetRef ref,
  Part part,
) async {
  final isAdmin = ref.read(isAdminProvider);
  if (!isAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hanya pemilik yang dapat melakukan koreksi stok'),
      ),
    );
    return;
  }

  final deltaController = TextEditingController();
  final reasonController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var saving = false;

  await showNeoDialog<void>(
    context: context,
    child: StatefulBuilder(
      builder: (context, setState) {
        final textTheme = AppTypography.textTheme();
        final delta = double.tryParse(deltaController.text) ?? 0;
        final resulting = previewAdjustStock(part.stockQty, delta);
        final canSubmit = canAdjustStock(part.stockQty, delta) &&
            reasonController.text.trim().isNotEmpty &&
            !saving;

        String formatQty(double value) {
          final normalized = value.truncateToDouble() == value
              ? value.toInt().toString()
              : value.toString();
          return normalized;
        }

        return NeoDialog.alert(
          title: 'Koreksi Stok',
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoTextField(
                  controller: deltaController,
                  labelText: 'Perubahan (negatif untuk kurang)',
                  prefixIcon: AppIcons.refresh,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan jumlah perubahan';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Masukkan angka yang valid';
                    }
                    if (parsed == 0) {
                      return 'Perubahan tidak boleh 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  controller: reasonController,
                  labelText: 'Alasan',
                  prefixIcon: AppIcons.notepad,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return emptyReasonMessage;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                NeoCard.info(
                  color: resulting < 0
                      ? AppColors.pastelPink
                      : AppColors.bgSurface,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stok Hasil', style: textTheme.bodyMedium),
                      Text(
                        formatQty(resulting),
                        style: AppTypography.chakra(
                          fontSize: 24,
                          color: resulting < 0
                              ? AppColors.statusDanger
                              : AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!canAdjustStock(part.stockQty, delta) &&
                    deltaController.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      insufficientStockMessage,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.statusDanger),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 8),
            ThickBottomBorderButton(
              onPressed: canSubmit
                  ? () async {
                      if (!formKey.currentState!.validate()) return;
                      final deltaValue =
                          double.parse(deltaController.text.trim());
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(partDetailControllerProvider(part.id)
                                .notifier)
                            .adjustStock(
                              deltaValue,
                              reasonController.text,
                            );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Koreksi stok berhasil dicatat'),
                          ),
                        );
                      } catch (e) {
                        setState(() => saving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  : null,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );
}
