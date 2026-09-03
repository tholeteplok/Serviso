import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/wo_status.dart';
import '../../auth/controllers/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/plate_chip.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../inventori/controllers/part_providers.dart';
import '../../inventori/models/part.dart';

import '../controllers/wo_detail_controller.dart';
import '../controllers/work_order_providers.dart';
import '../logic/wo_state_machine.dart';
import '../models/payment.dart';
import '../models/work_order.dart';
import '../../settings/data/settings_repository.dart';
import '../pdf/receipt_actions.dart';
import '../screens/payment_sheet.dart';

class WoDetailScreen extends ConsumerStatefulWidget {
  const WoDetailScreen({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  ConsumerState<WoDetailScreen> createState() => _WoDetailScreenState();
}

class _WoDetailScreenState extends ConsumerState<WoDetailScreen> {
  Future<bool> _confirm({
    required String title,
    required String message,
    String confirmLabel = 'Lanjut',
    Color? confirmColor,
  }) async {
    final result = await showNeoConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDanger: confirmColor != null,
    );
    return result == true;
  }

  Future<void> _onStart() async {
    try {
      await ref
          .read(woDetailControllerProvider(widget.workOrderId).notifier)
          .start();
      ref.invalidate(boardControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work order mulai dikerjakan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _onComplete() async {
    final order =
        ref.read(woDetailControllerProvider(widget.workOrderId)).valueOrNull;
    if (order == null) return;

    final hasParts = order.items.any((i) => i.kind == WoItemKind.part);
    final hasJasa = order.items.any((i) => i.kind == WoItemKind.jasa);

    String message;
    if (hasParts && hasJasa) {
      message =
          'Pekerjaan selesai & stok suku cadang akan dikurangi otomatis. Total tagihan: ${rupiah(order.total)}.';
    } else if (hasParts) {
      message =
          'Stok suku cadang akan dikurangi otomatis dari inventori. Total tagihan: ${rupiah(order.total)}.';
    } else if (hasJasa) {
      message =
          'Pekerjaan jasa telah selesai. Total tagihan: ${rupiah(order.total)}.';
    } else {
      message =
          'Selesaikan work order ini? Total tagihan: ${rupiah(order.total)}.';
    }

    final confirmed = await _confirm(
      title: 'Selesaikan work order?',
      message: message,
      confirmLabel: 'Selesaikan',
    );
    if (!confirmed) return;
    try {
      await ref
          .read(woDetailControllerProvider(widget.workOrderId).notifier)
          .complete();
      ref.invalidate(boardControllerProvider);
      final updated =
          ref.read(woDetailControllerProvider(widget.workOrderId)).valueOrNull;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Work order selesai'),
            duration: const Duration(seconds: 3),
            action: updated == null
                ? null
                : SnackBarAction(
                    label: 'Struk',
                    onPressed: () => _onReceipt(updated),
                  ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _onCancel() async {
    final order =
        ref.read(woDetailControllerProvider(widget.workOrderId)).valueOrNull;
    if (order == null) return;
    final isCompleted = order.status == WoStatus.selesai;
    final isWaiting = order.status == WoStatus.menunggu;
    final warning = isCompleted
        ? 'Work order sudah selesai. Membatalkan akan mengembalikan stok part ke inventori.'
        : isWaiting
            ? 'Hapus work order ini dari daftar antrian?'
            : 'Work order akan dibatalkan dan tidak dapat dikerjakan lagi.';
    final confirmed = await _confirm(
      title: isWaiting ? 'Hapus antrian?' : 'Batalkan work order?',
      message: warning,
      confirmLabel: isWaiting ? 'Hapus' : 'Batalkan',
      confirmColor: AppColors.action,
    );
    if (!confirmed) return;
    try {
      await ref
          .read(woDetailControllerProvider(widget.workOrderId).notifier)
          .cancel();
      ref.invalidate(boardControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWaiting
                ? 'Antrian berhasil dibatalkan'
                : 'Work order dibatalkan'),
            duration: const Duration(seconds: 2),
          ),
        );
        if (isWaiting) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _onAddJasa() async {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final added = await showNeoDialog<bool>(
      context: context,
      builder: (dialogCtx) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Jasa',
              style: AppTypography.chakra(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 16),
            NeoTextField(
              controller: descCtrl,
              labelText: 'Deskripsi Jasa',
              autofocus: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: priceCtrl,
              labelText: 'Harga Jasa',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (v) {
                final p = double.tryParse(v?.trim() ?? '');
                if (p == null || p <= 0) return 'Harga harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ThickBottomBorderButton(
                  variant: ThickButtonVariant.secondary,
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 10),
                ThickBottomBorderButton(
                  variant: ThickButtonVariant.primary,
                  onPressed: () {
                    if (formKey.currentState?.validate() == true) {
                      Navigator.of(dialogCtx).pop(true);
                    }
                  },
                  child: const Text('Tambah'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (added == true) {
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      try {
        await ref
            .read(woDetailControllerProvider(widget.workOrderId).notifier)
            .addItem(
              WoItemInput(
                kind: WoItemKind.jasa,
                description: descCtrl.text.trim(),
                qty: 1,
                unitPrice: price,
              ),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jasa berhasil ditambahkan'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _onAddPart() async {
    final selectedPart = await showModalBottomSheet<Part>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => const _DetailPartPickerSheet(),
    );

    if (selectedPart == null || !mounted) return;

    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(
      text: selectedPart.sellPrice.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showNeoDialog<bool>(
      context: context,
      builder: (dialogCtx) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah ${selectedPart.name}',
              style: AppTypography.chakra(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok tersedia: ${selectedPart.stockQty.toStringAsFixed(0)} ${selectedPart.unit ?? 'pcs'}',
              style: AppTypography.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            NeoTextField(
              controller: qtyCtrl,
              labelText: 'Jumlah (Qty)',
              keyboardType: TextInputType.number,
              autofocus: true,
              validator: (v) {
                final q = double.tryParse(v?.trim() ?? '');
                if (q == null || q <= 0) return 'Jumlah harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: priceCtrl,
              labelText: 'Harga Satuan',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (v) {
                final p = double.tryParse(v?.trim() ?? '');
                if (p == null || p <= 0) return 'Harga harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ThickBottomBorderButton(
                  variant: ThickButtonVariant.secondary,
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 10),
                ThickBottomBorderButton(
                  variant: ThickButtonVariant.primary,
                  onPressed: () {
                    if (formKey.currentState?.validate() == true) {
                      Navigator.of(dialogCtx).pop(true);
                    }
                  },
                  child: const Text('Tambah'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1;
      final price =
          double.tryParse(priceCtrl.text.trim()) ?? selectedPart.sellPrice;
      try {
        await ref
            .read(woDetailControllerProvider(widget.workOrderId).notifier)
            .addItem(
              WoItemInput(
                kind: WoItemKind.part,
                partId: selectedPart.id,
                partName: selectedPart.name,
                description: selectedPart.name,
                qty: qty,
                unitPrice: price,
              ),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Part berhasil ditambahkan'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _onRemoveItem(String itemId) async {
    final confirmed = await _confirm(
      title: 'Hapus item?',
      message: 'Item ini akan dihapus dari work order.',
      confirmLabel: 'Hapus',
      confirmColor: AppColors.action,
    );
    if (!confirmed) return;
    try {
      await ref
          .read(woDetailControllerProvider(widget.workOrderId).notifier)
          .removeItem(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item berhasil dihapus'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _onPay(WorkOrder order) async {
    await showNeoBottomSheet(
      context: context,
      child: PaymentSheet(
        order: order,
        onPaid: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil dicatat'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onReceipt(WorkOrder order) async {
    final profile = ref.read(sessionProvider).valueOrNull;
    final fullName = profile?.fullName ?? 'Kasir';
    if (!mounted) return;
    if (profile == null) return;
    final settings = ref.read(settingsProvider).valueOrNull;
    showReceiptOptions(
      context: context,
      order: order,
      profile: profile,
      printedBy: fullName,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final state = ref.watch(woDetailControllerProvider(widget.workOrderId));

    return Scaffold(
      appBar: const NeoAppBar(title: 'Detail Work Order'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(woDetailControllerProvider(widget.workOrderId)),
        ),
        data: (order) => _DetailBody(
          order: order,
          isAdmin: isAdmin,
          onStart: _onStart,
          onComplete: _onComplete,
          onCancel: _onCancel,
          onPay: _onPay,
          onReceipt: _onReceipt,
          onAddJasa: _onAddJasa,
          onAddPart: _onAddPart,
          onRemoveItem: _onRemoveItem,
          onEdit: (complaint, diagnosis, techNote) => ref
              .read(woDetailControllerProvider(widget.workOrderId).notifier)
              .updateDetail(
                complaint: complaint,
                diagnosis: diagnosis,
                techNote: techNote,
              ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.order,
    required this.isAdmin,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
    required this.onPay,
    required this.onReceipt,
    required this.onAddJasa,
    required this.onAddPart,
    required this.onRemoveItem,
    required this.onEdit,
  });

  final WorkOrder order;
  final bool isAdmin;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final Future<void> Function(WorkOrder) onPay;
  final Future<void> Function(WorkOrder) onReceipt;
  final VoidCallback onAddJasa;
  final VoidCallback onAddPart;
  final Future<void> Function(String) onRemoveItem;
  final Future<void> Function(String?, String?, String?) onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final editable = order.status == WoStatus.dikerjakan;
    final canEditItems = order.status == WoStatus.menunggu ||
        order.status == WoStatus.dikerjakan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusChip(status: order.status),
              if (order.status == WoStatus.selesai) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.isPaid
                        ? AppColors.statusDone
                        : AppColors.pastelPink,
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: AppColors.borderInk,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    order.isPaid ? 'Lunas' : 'Belum Bayar',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.ink900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (order.isPaid && order.payMethod != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: AppColors.borderInk, width: 1.5),
                    ),
                    child: Text(
                      order.payMethod!.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
              const Spacer(),
              Text(
                order.woNumber,
                style: AppTypography.mono(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeoCard.info(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (order.plateNo != null) ...[
                      PlateChip(plateText: order.plateNo!),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        order.vehicleDesc ?? 'Kendaraan',
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  order.customerName ?? 'Pelanggan',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (order.odometerIn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'KM masuk: ${order.odometerIn}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeoCard.info(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keluhan', style: textTheme.labelMedium),
                const SizedBox(height: 6),
                _EditableField(
                  initial: order.complaint ?? '',
                  readOnly: !editable,
                  maxLines: 3,
                  onSaved: (value) =>
                      onEdit(value, order.diagnosis, order.techNote),
                ),
                const SizedBox(height: 12),
                Text('Diagnosis', style: textTheme.labelMedium),
                const SizedBox(height: 6),
                _EditableField(
                  initial: order.diagnosis ?? '',
                  readOnly: !editable,
                  maxLines: 3,
                  onSaved: (value) =>
                      onEdit(order.complaint, value, order.techNote),
                ),
                const SizedBox(height: 12),
                Text('Catatan teknisi', style: textTheme.labelMedium),
                const SizedBox(height: 6),
                _EditableField(
                  initial: order.techNote ?? '',
                  readOnly: !editable,
                  maxLines: 2,
                  onSaved: (value) =>
                      onEdit(order.complaint, order.diagnosis, value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeoCard.info(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Item', style: textTheme.titleMedium),
                    ),
                      if (canEditItems) ...[
                        TextButton.icon(
                          onPressed: onAddJasa,
                          icon: Icon(AppIcons.add, size: 16),
                          label: const Text('Jasa'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: onAddPart,
                          icon: Icon(AppIcons.add, size: 16),
                          label: const Text('Part'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (order.items.isEmpty)
                    Text(
                      'Belum ada item.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.inkMuted),
                    )
                  else
                    ...order.items.map(
                      (item) => _ItemRow(
                        item: item,
                        canDelete: canEditItems,
                        onDelete: () => onRemoveItem(item.id),
                      ),
                    ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: textTheme.titleMedium),
                      Text(
                        rupiah(order.total),
                        style: AppTypography.mono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (order.isPaid) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dibayar', style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(rupiah(order.paidAmount), style: AppTypography.mono(fontWeight: FontWeight.w600)),
                            if (order.payMethod != null)
                              Text(order.payMethod!.label, style: textTheme.labelSmall?.copyWith(color: AppColors.inkMuted)),
                          ],
                        ),
                      ],
                    ),
                    if (order.paidAt != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Waktu Bayar', style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
                          Text(dateTimeId(order.paidAt!), style: textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          _ActionButtons(
            status: order.status,
            isPaid: order.isPaid,
            isAdmin: isAdmin,
            onStart: onStart,
            onComplete: onComplete,
            onCancel: onCancel,
            onPay: () => onPay(order),
            onReceipt: () => onReceipt(order),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    this.canDelete = false,
    this.onDelete,
  });

  final WoItem item;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final icon = item.kind == WoItemKind.part
        ? AppIcons.part
        : AppIcons.wrench;
    final title = item.kind == WoItemKind.part
        ? (item.partName ?? item.description ?? 'Part')
        : (item.description ?? 'Jasa');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  item.kind == WoItemKind.part
                      ? '${item.qty.toStringAsFixed(0)}x · ${rupiah(item.unitPrice)}'
                      : rupiah(item.unitPrice),
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          Text(
            rupiah(item.lineTotal),
            style: AppTypography.mono(fontWeight: FontWeight.w600),
          ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                AppIcons.trash,
                size: 18,
                color: AppColors.action,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableField extends StatefulWidget {
  const _EditableField({
    required this.initial,
    required this.readOnly,
    required this.maxLines,
    required this.onSaved,
  });

  final String initial;
  final bool readOnly;
  final int maxLines;
  final Future<void> Function(String) onSaved;

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _submit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && !_focus.hasFocus) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim() == widget.initial.trim()) return;
    await widget.onSaved(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return NeoTextField(
      controller: _controller,
      focusNode: _focus,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      hintText: widget.readOnly ? 'Tidak tersedia' : 'Isi di sini',
      suffixIcon: widget.readOnly
          ? null
          : Icon(AppIcons.edit, size: 16, color: AppColors.textSecondary),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.isPaid,
    required this.isAdmin,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
    required this.onPay,
    required this.onReceipt,
  });

  final WoStatus status;
  final bool isPaid;
  final bool isAdmin;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onPay;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    final canStart = WoStateMachine.canTransition(status, WoEvent.start) &&
        status == WoStatus.menunggu;
    final canComplete =
        WoStateMachine.canTransition(status, WoEvent.complete);
    final canCancel = WoStateMachine.canTransition(status, WoEvent.cancel) &&
        (status != WoStatus.dibatalkan) &&
        (isAdmin || status == WoStatus.menunggu);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canStart)
          ThickBottomBorderButton(
            onPressed: onStart,
            isFullWidth: true,
            variant: ThickButtonVariant.primary,
            icon: Icon(AppIcons.wrench, color: AppColors.ink900, size: 20),
            child: const Text('Mulai Kerja'),
          ),
        if (canComplete) ...[
          ThickBottomBorderButton(
            onPressed: onComplete,
            isFullWidth: true,
            variant: ThickButtonVariant.primary,
            icon: Icon(AppIcons.checkCircle, color: AppColors.ink900, size: 20),
            child: const Text('Selesaikan'),
          ),
        ],
        if (status == WoStatus.selesai) ...[
          if (!isPaid)
            ThickBottomBorderButton(
              onPressed: onPay,
              isFullWidth: true,
              variant: ThickButtonVariant.primary,
              icon: Icon(AppIcons.wallet, color: AppColors.ink900, size: 20),
              child: const Text('Pembayaran'),
            )
          else
            ThickBottomBorderButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).pop();
              },
              isFullWidth: true,
              variant: ThickButtonVariant.primary,
              icon: Icon(AppIcons.check, color: AppColors.ink900, size: 20),
              child: const Text('Selesai'),
            ),
          const SizedBox(height: 12),
          ThickBottomBorderButton(
            onPressed: onReceipt,
            isFullWidth: true,
            variant: ThickButtonVariant.secondary,
            icon: Icon(AppIcons.receipt, color: AppColors.ink900, size: 20),
            child: const Text('Struk'),
          ),
        ],
        if (canCancel) ...[
          const SizedBox(height: 12),
          ThickBottomBorderButton(
            onPressed: onCancel,
            isFullWidth: true,
            variant: ThickButtonVariant.danger,
            icon: Icon(AppIcons.prohibit, color: AppColors.ink900, size: 20),
            child: Text(
              status == WoStatus.selesai
                  ? 'Batalkan (kembalikan stok)'
                  : 'Batalkan',
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailPartPickerSheet extends ConsumerStatefulWidget {
  const _DetailPartPickerSheet();

  @override
  ConsumerState<_DetailPartPickerSheet> createState() =>
      _DetailPartPickerSheetState();
}

class _DetailPartPickerSheetState
    extends ConsumerState<_DetailPartPickerSheet> {
  final _searchController = TextEditingController();
  List<Part>? _parts;
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchParts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchParts([String? query]) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(partRepositoryProvider);
      final result = await repo.list(
        search: query?.trim().isEmpty == true ? null : query?.trim(),
      );
      if (mounted) {
        setState(() {
          _parts = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _parts = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pilih Suku Cadang', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode part...',
                prefixIcon: Icon(AppIcons.search),
                suffixIcon: IconButton(
                  icon: Icon(AppIcons.barcode),
                  tooltip: 'Scan Barcode',
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final code = await showBarcodeScanner(context);
                    if (code != null && code.isNotEmpty) {
                      _searchController.text = code;
                      await _fetchParts(code);
                      if (_parts != null && _parts!.length == 1 && mounted) {
                        nav.pop(_parts!.first);
                      }
                    }
                  },
                ),
              ),
              onChanged: (q) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () => _fetchParts(q));
              },
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_parts == null || _parts!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tidak ada suku cadang ditemukan',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scroll,
                  itemCount: _parts!.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final part = _parts![index];
                    return ListTile(
                      title: Text(part.name, style: textTheme.titleSmall),
                      subtitle: Text(
                        'Stok: ${part.stockQty.toStringAsFixed(0)} ${part.unit ?? 'pcs'} • ${rupiah(part.sellPrice)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      trailing: Icon(AppIcons.caretRight, size: 18, color: AppColors.ink900),
                      onTap: () => Navigator.of(context).pop(part),
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

