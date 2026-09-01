import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/controllers/session_controller.dart';
import '../../inventori/controllers/part_list_controller.dart';
import '../../inventori/models/part.dart';

import '../../laporan/controllers/report_controllers.dart';
import '../../workorders/models/payment.dart';
import '../../workorders/models/work_order.dart';
import '../../workorders/pdf/receipt_builder.dart';
import '../data/direct_sale_repository.dart';
import '../models/direct_sale.dart';

final directSaleRepositoryProvider = Provider<DirectSaleRepository>((ref) {
  final client = Supabase.instance.client;
  return SupabaseDirectSaleRepository(client);
});

class DirectSaleScreen extends ConsumerStatefulWidget {
  const DirectSaleScreen({super.key});
  @override
  ConsumerState<DirectSaleScreen> createState() => _DirectSaleScreenState();
}

class _DirectSaleScreenState extends ConsumerState<DirectSaleScreen> {
  final List<DirectSaleItemInput> _items = [];
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  String? _error;
  String? _customerId;

  // part picker state
  final _qtyCtrl = TextEditingController(text: '1');
  Part? _selectedPart;

  double get _total => _items.fold(0.0, (s, e) => s + e.lineTotal);

  Future<void> _addPart() async {
    if (_selectedPart == null) return;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _error = 'Jumlah harus >0');
      return;
    }
    final part = _selectedPart!;
    setState(() {
      _items.add(DirectSaleItemInput(
        kind: WoItemKind.part,
        partId: part.id,
        description: part.name,
        qty: qty,
        unitPrice: part.sellPrice,
      ));
      _selectedPart = null;
      _error = null;
    });
  }

  Future<void> _addJasaDialog() async {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final res = await showDialog<DirectSaleItemInput>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Jasa'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi jasa')),
          const SizedBox(height: 8),
          TextFormField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp '), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              onPressed: () {
                final d = descCtrl.text.trim();
                final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
                if (d.isEmpty || p <= 0) return;
                Navigator.pop(ctx, DirectSaleItemInput(kind: WoItemKind.jasa, qty: 1, unitPrice: p, description: d));
              },
              child: const Text('Tambah')),
        ],
      ),
    );
    if (res != null) setState(() => _items.add(res));
  }

  ReceiptInput _buildReceiptInput({
    required String saleNumber,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
    required String printedBy,
  }) {
    return ReceiptInput(
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      woNumber: saleNumber,
      plate: 'Penjualan Langsung',
      vehicleDesc: null,
      customerName: null,
      items: _items
          .map((e) => WoItem(
                id: e.partId ?? 'jasa-${e.description}',
                kind: e.kind,
                partId: e.partId,
                description: e.description,
                qty: e.qty,
                unitPrice: e.unitPrice,
                discount: e.discount,
              ))
          .toList(),
      total: _total,
      payMethod: _method.label,
      paidAmount: _total,
      printedBy: printedBy,
      printedAt: DateTime.now(),
    );
  }

  Future<void> _shareReceipt(ReceiptInput input) async {
    final res = await buildReceiptPdf(input);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${res.filename}');
    await f.writeAsBytes(res.bytes);
    await Printing.sharePdf(bytes: await f.readAsBytes(), filename: res.filename);
  }

  Future<void> _previewReceipt(ReceiptInput input) async {
    final res = await buildReceiptPdf(input);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${res.filename}');
    await f.writeAsBytes(res.bytes);
    await Printing.layoutPdf(
        name: res.filename, onLayout: (fmt) async => Uint8List.fromList(await f.readAsBytes()));
  }

  void _showReceiptOptions(ReceiptInput input) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Bagikan PDF'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _shareReceipt(input);
              }),
          ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Pratinjau'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _previewReceipt(input);
              }),
          ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Selesai'),
              onTap: () => Navigator.pop(sheetCtx)),
        ]),
      ),
    );
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Minimal 1 item diperlukan');
      return;
    }
    if (_total <= 0) {
      setState(() => _error = 'Total tidak valid');
      return;
    }
    final paid = _total;
    final v = validatePaymentAmount(paid, _total);
    if (!v.isValid) {
      setState(() => _error = v.error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(directSaleRepositoryProvider);
      final draft = DirectSaleDraft(
          customerId: _customerId, items: List.of(_items), payMethod: _method, paidAmount: paid);
      final saleId = await repo.checkout(draft);
      if (!mounted) return;
      // Ambil shop settings & printedBy
      String shopName = 'Bengkel';
      String? shopAddress;
      String? shopPhone;
      try {
        final profile = ref.read(sessionProvider).valueOrNull;
        if (profile != null) {
          shopName = profile.shopName ?? 'Bengkel';
        }
      } catch (_) {}
      final printedBy = ref.read(sessionProvider).valueOrNull?.fullName.isNotEmpty == true
          ? ref.read(sessionProvider).valueOrNull!.fullName
          : ref.read(sessionProvider).valueOrNull?.username ?? 'Kasir';
      final input = _buildReceiptInput(
          saleNumber: saleId, shopName: shopName, shopAddress: shopAddress, shopPhone: shopPhone, printedBy: printedBy);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Penjualan ${input.woNumber} berhasil')));
      // Invalidate laporan & inventori agar pendapatan & stok update langsung
      ref.invalidate(partListControllerProvider);
      try {
        // laporan providers — lazy import via dynamic to avoid circular
        // ignore: avoid_dynamic_calls
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(laporanDailySummariesProvider);
        ref.invalidate(topPartsProvider);
        ref.invalidate(ownerFinancialSummaryProvider);
      } catch (_) {}
      _showReceiptOptions(input);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Scaffold(
      appBar: AppBar(title: const Text('Penjualan Langsung'), leading: IconButton(icon: Icon(AppIcons.back), onPressed: () => context.pop())),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionCard(
          title: 'Keranjang',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_items.isEmpty) Text('Belum ada item', style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted)),
            for (int i = 0; i < _items.length; i++)
              ListTile(
                dense: true,
                title: Text(_items[i].description ?? _items[i].partId ?? 'Jasa', style: AppTypography.mono(fontSize: 13)),
                subtitle: Text('${_items[i].qty} x ${rupiah(_items[i].unitPrice)} = ${rupiah(_items[i].lineTotal)}', style: AppTypography.mono(fontSize: 12)),
                trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _items.removeAt(i))),
              ),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: textTheme.titleMedium),
              Text(rupiah(_total), style: AppTypography.mono(fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Tambah Part',
          child: Column(children: [
            Consumer(builder: (ctx, ref2, _) {
              final partsAsync = ref2.watch(partListControllerProvider);
              return partsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Gagal muat part: $e'),
                data: (state) {
                  final parts = state.items.take(50).toList();
                  return DropdownMenu<Part>(
                    width: double.infinity,
                    label: const Text('Pilih part'),
                    onSelected: (p) => setState(() => _selectedPart = p),
                    dropdownMenuEntries: parts.map((p) => DropdownMenuEntry(value: p, label: '${p.name} • ${rupiah(p.sellPrice)} • stok ${p.stockQty}')).toList(),
                  );
                },
              );
            }),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _addPart, icon: Icon(AppIcons.add, size: 16), label: const Text('Tambah Part')),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _addJasaDialog, icon: Icon(AppIcons.add, size: 16), label: const Text('Tambah Jasa Custom')),
          ]),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Pembayaran',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Metode', style: textTheme.labelMedium),
            const SizedBox(height: 8),
            NeoSegmentControl<PaymentMethod>(
              selectedValue: _method,
              onValueChanged: (v) => setState(() => _method = v),
              items: PaymentMethod.values.map((m) => NeoSegmentItem(value: m, label: m.label, activeColor: AppColors.pastelMint)).toList(),
            ),
          ]),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: textTheme.bodyMedium?.copyWith(color: AppColors.action)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _saving ? null : _checkout, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Selesaikan & Cetak Struk')),
        ),
      ]),
    );
  }
}

