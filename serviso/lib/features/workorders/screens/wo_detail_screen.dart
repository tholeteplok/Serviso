import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/wo_status.dart';
import '../../auth/controllers/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/plate_chip.dart';
import '../../../core/widgets/status_chip.dart';
import '../../settings/data/settings_repository.dart';
import '../controllers/wo_detail_controller.dart';
import '../controllers/work_order_providers.dart';
import '../logic/wo_state_machine.dart';
import '../models/work_order.dart';
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
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: confirmColor == null
                ? null
                : FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _onStart() async {
    try {
      await ref.read(woDetailControllerProvider(widget.workOrderId).notifier).start();
      ref.invalidate(boardControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work order mulai dikerjakan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _onComplete() async {
    final order = ref.read(woDetailControllerProvider(widget.workOrderId)).valueOrNull;
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
      await ref.read(woDetailControllerProvider(widget.workOrderId).notifier).complete();
      ref.invalidate(boardControllerProvider);
      final updated = ref.read(woDetailControllerProvider(widget.workOrderId)).valueOrNull;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Work order selesai'),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _onCancel() async {
    final order = ref.read(woDetailControllerProvider(widget.workOrderId)).valueOrNull;
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
      await ref.read(woDetailControllerProvider(widget.workOrderId).notifier).cancel();
      ref.invalidate(boardControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWaiting ? 'Antrian berhasil dibatalkan' : 'Work order dibatalkan'),
          ),
        );
        if (isWaiting) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _onPay(WorkOrder order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PaymentSheet(
        order: order,
        onPaid: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pembayaran dicatat'),
              action: SnackBarAction(
                label: 'Struk',
                onPressed: () => _onReceipt(order),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onReceipt(WorkOrder order) async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    final fullName =
        ref.read(sessionProvider).valueOrNull?.fullName ?? 'Kasir';
    if (!mounted) return;
    showReceiptOptions(
      context: context,
      order: order,
      settings: settings,
      printedBy: fullName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final state = ref.watch(woDetailControllerProvider(widget.workOrderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Work Order')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(woDetailControllerProvider(widget.workOrderId)),
        ),
        data: (order) => _DetailBody(
          order: order,
          isAdmin: isAdmin,
          onStart: _onStart,
          onComplete: _onComplete,
          onCancel: _onCancel,
          onPay: _onPay,
          onReceipt: _onReceipt,
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
    required this.onEdit,
  });

  final WorkOrder order;
  final bool isAdmin;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final Future<void> Function(WorkOrder) onPay;
  final Future<void> Function(WorkOrder) onReceipt;
  final Future<void> Function(String?, String?, String?) onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final editable = order.status == WoStatus.dikerjakan;

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.isPaid
                      ? AppColors.tintOf(AppColors.teal)
                      : AppColors.tintOf(AppColors.inkMuted),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.paymentStatusLabel,
                  style: AppTypography.textTheme().labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: order.isPaid
                            ? AppColors.teal
                            : AppColors.inkMuted,
                      ),
                ),
              ),
            ],
            const Spacer(),
            Expanded(
              child: Text(
                order.woNumber,
                style: AppTypography.mono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlateChip(plateText: order.plateNo ?? '—'),
                const SizedBox(height: 8),
                Text(
                  order.vehicleDesc ?? 'Kendaraan',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  order.customerName ?? 'Pelanggan',
                  style: textTheme.titleMedium,
                ),
                if (order.odometerIn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'KM masuk: ${order.odometerIn}',
                    style: AppTypography.mono(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
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
                  onSaved: (value) => onEdit(value, order.diagnosis, order.techNote),
                ),
                const SizedBox(height: 12),
                Text('Diagnosis', style: textTheme.labelMedium),
                const SizedBox(height: 6),
                _EditableField(
                  initial: order.diagnosis ?? '',
                  readOnly: !editable,
                  maxLines: 3,
                  onSaved: (value) => onEdit(order.complaint, value, order.techNote),
                ),
                const SizedBox(height: 12),
                Text('Catatan teknisi', style: textTheme.labelMedium),
                const SizedBox(height: 6),
                _EditableField(
                  initial: order.techNote ?? '',
                  readOnly: !editable,
                  maxLines: 2,
                  onSaved: (value) => onEdit(order.complaint, order.diagnosis, value),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                if (order.items.isEmpty)
                  Text(
                    'Belum ada item.',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                  )
                else
                  ...order.items.map((item) => _ItemRow(item: item)),
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
              ],
            ),
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
  const _ItemRow({required this.item});

  final WoItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final icon = item.kind == WoItemKind.part
        ? Icons.build_outlined
        : Icons.handyman_outlined;
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
                Text(
                  '${item.qty} x ${rupiah(item.unitPrice)}',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          Text(
            rupiah(item.lineTotal),
            style: AppTypography.mono(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatefulWidget {
  const _EditableField({
    required this.initial,
    required this.readOnly,
    required this.onSaved,
    this.maxLines = 1,
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
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial &&
        _controller.text != widget.initial) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_controller.text.trim() == widget.initial.trim()) return;
    await widget.onSaved(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        hintText: widget.readOnly ? 'Tidak tersedia' : 'Isi di sini',
        suffixIcon: widget.readOnly
            ? null
            : const Icon(Icons.edit_outlined, size: 16),
      ),
      style: widget.readOnly
          ? textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted)
          : textTheme.bodyMedium,
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
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Mulai Kerja'),
          ),
        if (canComplete) ...[
          FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Selesaikan'),
          ),
        ],
        if (status == WoStatus.selesai) ...[
          if (!isPaid)
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pembayaran'),
            )
          else
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check),
              label: const Text('Selesai'),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReceipt,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Struk'),
          ),
        ],
        if (canCancel) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: Text(status == WoStatus.selesai
                ? 'Batalkan (kembalikan stok)'
                : 'Batalkan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.action,
              side: const BorderSide(color: AppColors.action),
            ),
          ),
        ],
      ],
    );
  }
}
