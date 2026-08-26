import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../controllers/part_detail_controller.dart';

Future<void> showStockInDialog(
  BuildContext context,
  WidgetRef ref,
  String partId,
) async {
  final qtyController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final textTheme = AppTypography.textTheme();
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Stok Masuk'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Jumlah stok masuk harus lebih dari 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Menambah stok via pembelian.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final qty =
                            double.parse(qtyController.text.trim());
                        setState(() => saving = true);
                        try {
                          await ref
                              .read(partDetailControllerProvider(partId)
                                  .notifier)
                              .stockIn(qty, note: noteController.text);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stok masuk berhasil dicatat'),
                            ),
                          );
                        } catch (e) {
                          setState(() => saving = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
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
      );
    },
  );
}
