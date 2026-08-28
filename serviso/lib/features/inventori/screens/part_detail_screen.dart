import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_detail_controller.dart';
import '../models/part.dart';
import '../models/part_movement.dart';
import 'adjust_stock_dialog.dart';
import 'part_form_sheet.dart';
import 'stock_in_dialog.dart';

class PartDetailScreen extends ConsumerWidget {
  const PartDetailScreen({super.key, required this.partId});

  final String partId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    final state = ref.watch(partDetailControllerProvider(partId));
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Suku Cadang'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah suku cadang',
              onPressed: () {
                final currentPart = state.valueOrNull?.part;
                if (currentPart != null) {
                  showPartForm(
                    context,
                    ref,
                    currentPart,
                    onSaved: () => ref
                        .read(partDetailControllerProvider(partId).notifier)
                        .reload(),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus suku cadang',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(partDetailControllerProvider(partId).notifier).reload(),
        ),
        data: (data) {
          final part = data.part;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(part.name, style: textTheme.headlineSmall),
                  ),
                  if (part.code != null) ...[
                    Text(
                      part.code!,
                      style: AppTypography.mono(
                        fontSize: 14,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (isAdmin)
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Ubah'),
                      onPressed: () => showPartForm(
                        context,
                        ref,
                        part,
                        onSaved: () => ref
                            .read(partDetailControllerProvider(partId).notifier)
                            .reload(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: part.isLowStock
                      ? AppColors.tintAction
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: part.isLowStock ? AppColors.action : AppColors.line,
                  ),
                ),
                child: Column(
                  children: [
                    Text('Stok Tersedia', style: textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      _formatStock(part),
                      style: AppTypography.chakra(
                        fontSize: 48,
                        color:
                            part.isLowStock ? AppColors.action : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${part.unit ?? 'pcs'}'
                      '${part.isLowStock ? ' • Stok Menipis' : ''}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Harga',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Modal Beli',
                      value: rupiah(part.costPrice),
                      mono: true,
                    ),
                    const Divider(height: 12),
                    _InfoRow(
                      icon: Icons.sell_outlined,
                      label: 'Harga Jual',
                      value: rupiah(part.sellPrice),
                      mono: true,
                    ),
                    const Divider(height: 12),
                    _InfoRow(
                      icon: Icons.warning_outlined,
                      label: 'Batas Stok Menipis',
                      value: '${part.minStock} ${part.unit ?? 'pcs'}',
                      mono: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () =>
                          showStockInDialog(context, ref, partId),
                      child: const Text('Stok Masuk'),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.tintAction,
                          foregroundColor: AppColors.action,
                        ),
                        onPressed: () => showAdjustStockDialog(
                          context,
                          ref,
                          part,
                        ),
                        child: const Text('Koreksi Stok'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Kartu Stok',
                child: data.movements.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: EmptyState(
                          icon: Icons.history_outlined,
                          title: 'Belum ada pergerakan stok',
                          message:
                              'Stok masuk atau koreksi akan tercatat di sini.',
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.movements.length,
                        separatorBuilder: (_, _) => const Divider(height: 12),
                        itemBuilder: (context, index) =>
                            _MovementRow(movement: data.movements[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus suku cadang'),
        content: const Text(
          'Hapus suku cadang ini beserta seluruh kartu stoknya? Tindakan tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.action,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(partDetailControllerProvider(partId).notifier)
          .deletePart();
      if (!context.mounted) return;
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

String _formatStock(Part part) {
  final value = part.stockQty;
  final normalized = value.truncateToDouble() == value
      ? value.toInt().toString()
      : value.toString();
  return normalized;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: mono
                      ? AppTypography.mono(fontSize: 14)
                      : textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final PartMovement movement;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final isIn = movement.direction == MovementDirection.in_;
    final isAdjust = movement.direction == MovementDirection.adjust;
    final color = isIn
        ? AppColors.teal
        : (isAdjust ? AppColors.primary : AppColors.action);
    final qtyText = _formatSignedQty(movement.signedQuantity);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isIn
                ? Icons.add
                : (isAdjust ? Icons.edit_note : Icons.remove),
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _refLabel(movement),
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                '${movement.actorName ?? '—'} • ${timeId(movement.createdAt)}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          qtyText,
          style: AppTypography.mono(fontSize: 15, color: color),
        ),
      ],
    );
  }

  String _refLabel(PartMovement movement) {
    final base = movementRefLabel[movement.refType] ?? 'Stok';
    if (movement.note != null && movement.note!.isNotEmpty) {
      return '$base • ${movement.note}';
    }
    return base;
  }
}

String _formatSignedQty(double value) {
  final sign = value >= 0 ? '+' : '-';
  final abs = value.abs();
  final normalized =
      abs.truncateToDouble() == abs ? abs.toInt().toString() : abs.toString();
  return '$sign$normalized';
}
