import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadow.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_search_bar.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../../customers/controllers/customer_providers.dart';
import '../../customers/models/customer.dart';
import '../../inventori/controllers/part_list_controller.dart';
import '../../inventori/controllers/part_providers.dart';
import '../../inventori/models/part.dart';
import '../../laporan/controllers/report_controllers.dart';
import '../../settings/data/settings_repository.dart';
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
  // Cart state
  final List<DirectSaleItemInput> _items = [];
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  String? _error;

  // Search & Filter state
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua'; // 'Semua', 'Suku Cadang', 'Jasa'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Customer state (Walk-in vs Database)
  bool _isWalkIn = true;
  Customer? _selectedCustomer;

  int get _totalItemCount => _items.fold(0, (s, e) => s + e.qty.toInt());
  double get _total => _items.fold(0.0, (s, e) => s + e.lineTotal);

  // ---------------------------------------------------------------------------
  // Cart Actions
  // ---------------------------------------------------------------------------

  double _getPartQtyInCart(String partId) {
    for (final item in _items) {
      if (item.partId == partId) return item.qty;
    }
    return 0;
  }

  void _incrementPart(Part part) {
    if (part.stockQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok ${part.name} habis')),
      );
      return;
    }
    final existingIndex = _items.indexWhere((e) => e.partId == part.id);
    if (existingIndex >= 0) {
      final currentQty = _items[existingIndex].qty;
      if (currentQty >= part.stockQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maksimum stok ${part.name} tercapai (${part.stockQty.toInt()})',
            ),
          ),
        );
        return;
      }
      setState(() {
        _items[existingIndex] =
            _items[existingIndex].copyWith(qty: currentQty + 1);
      });
    } else {
      setState(() {
        _items.add(DirectSaleItemInput(
          kind: WoItemKind.part,
          partId: part.id,
          description: part.name,
          qty: 1,
          unitPrice: part.sellPrice,
        ));
      });
    }
  }

  void _decrementPart(Part part) {
    final existingIndex = _items.indexWhere((e) => e.partId == part.id);
    if (existingIndex < 0) return;
    final currentQty = _items[existingIndex].qty;
    setState(() {
      if (currentQty <= 1) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] =
            _items[existingIndex].copyWith(qty: currentQty - 1);
      }
    });
  }

  void _updateItemQty(int index, double newQty, {double? maxStock}) {
    if (newQty <= 0) {
      setState(() => _items.removeAt(index));
      return;
    }
    if (maxStock != null && newQty > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maksimum stok tercapai (${maxStock.toInt()})')),
      );
      return;
    }
    setState(() {
      _items[index] = _items[index].copyWith(qty: newQty);
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _clearCart() {
    setState(() {
      _items.clear();
      _selectedCustomer = null;
      _isWalkIn = true;
      _error = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  // ---------------------------------------------------------------------------
  // Custom Jasa Dialog
  // ---------------------------------------------------------------------------

  Future<void> _addJasaDialog() async {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final res = await showNeoDialog<DirectSaleItemInput>(
      context: context,
      child: NeoDialog.alert(
        title: 'Tambah Jasa Custom',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeoTextField(
              controller: descCtrl,
              labelText: 'Deskripsi Jasa',
              hintText: 'Misal: Jasa Pasang Ban / Cuci Karbu',
              prefixIcon: AppIcons.wrench,
            ),
            const SizedBox(height: 12),
            NeoTextField(
              controller: priceCtrl,
              labelText: 'Tarif Jasa',
              prefixText: 'Rp ',
              prefixIcon: AppIcons.money,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ThickBottomBorderButton(
            onPressed: () {
              final d = descCtrl.text.trim();
              final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
              if (d.isEmpty || p <= 0) return;
              Navigator.pop(
                context,
                DirectSaleItemInput(
                  kind: WoItemKind.jasa,
                  qty: 1,
                  unitPrice: p,
                  description: d,
                ),
              );
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (res != null) {
      setState(() => _items.add(res));
    }
  }

  // ---------------------------------------------------------------------------
  // Barcode Scanner
  // ---------------------------------------------------------------------------

  Future<void> _scanBarcode(List<Part> allParts) async {
    final code = await showBarcodeScanner(context);
    if (code == null || code.trim().isEmpty) return;
    final trimmed = code.trim();
    Part match = allParts.firstWhere(
      (p) =>
          (p.code?.trim().toLowerCase() == trimmed.toLowerCase()) ||
          (p.name.trim().toLowerCase() == trimmed.toLowerCase()),
      orElse: () => Part(
        id: '',
        name: '',
        stockQty: 0,
        createdAt: DateTime.now(),
      ),
    );

    // Fallback: cari langsung ke database jika suku cadang belum ter-cache di halaman aktif
    if (match.id.isEmpty) {
      try {
        final repo = ref.read(partRepositoryProvider);
        final found = await repo.list(search: trimmed, limit: 5);
        match = found.firstWhere(
          (p) =>
              (p.code?.trim().toLowerCase() == trimmed.toLowerCase()) ||
              (p.name.trim().toLowerCase() == trimmed.toLowerCase()),
          orElse: () => found.isNotEmpty ? found.first : match,
        );
      } catch (_) {}
    }

    if (match.id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode "$trimmed" tidak ditemukan di katalog')),
      );
      return;
    }

    _incrementPart(match);
    setState(() {
      _searchController.text = match.name;
      _searchQuery = match.name;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ditambahkan: ${match.name}')),
    );
  }

  // ---------------------------------------------------------------------------
  // Receipt Helpers
  // ---------------------------------------------------------------------------

  ReceiptInput _buildReceiptInput({
    required String saleNumber,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
    String? receiptNotes,
    required String printedBy,
    required List<DirectSaleItemInput> itemsSnapshot,
    required double totalSnapshot,
  }) {
    return ReceiptInput(
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      receiptNotes: receiptNotes,
      woNumber: saleNumber,
      plate: 'Penjualan Langsung',
      vehicleDesc: null,
      customerName: _isWalkIn ? 'Pelanggan Umum' : _selectedCustomer?.name,
      items: itemsSnapshot
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
      total: totalSnapshot,
      payMethod: _method.label,
      paidAmount: totalSnapshot,
      printedBy: printedBy,
      printedAt: DateTime.now(),
    );
  }

  Future<void> _shareReceipt(ReceiptInput input) async {
    final res = await buildReceiptPdf(input);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${res.filename}');
    await f.writeAsBytes(res.bytes);
    await Printing.sharePdf(
        bytes: await f.readAsBytes(), filename: res.filename);
  }

  Future<void> _previewReceipt(ReceiptInput input) async {
    final res = await buildReceiptPdf(input);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/${res.filename}');
    await f.writeAsBytes(res.bytes);
    await Printing.layoutPdf(
      name: res.filename,
      onLayout: (fmt) async => Uint8List.fromList(await f.readAsBytes()),
    );
  }

  // ---------------------------------------------------------------------------
  // Success Dialog with Safe Actions & Dual Options
  // ---------------------------------------------------------------------------

  void _showSuccessDialog(ReceiptInput input) {
    showNeoDialog(
      context: context,
      child: NeoDialog.alert(
        title: 'Transaksi Berhasil!',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.pastelMint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderInk, width: 2),
                boxShadow: AppShadow.l1,
              ),
              alignment: Alignment.center,
              child: Icon(AppIcons.checkFat, size: 28, color: AppColors.ink900),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppRadius.button,
                border: Border.all(color: AppColors.borderInk, width: 1.5),
              ),
              child: Text(
                'No. Nota: ${input.woNumber}',
                style: AppTypography.mono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              rupiah(input.total),
              style: AppTypography.chakra(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Metode Pembayaran: ${input.payMethod}',
              style: AppTypography.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ThickBottomBorderButton(
                    variant: ThickButtonVariant.secondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    onPressed: () => _shareReceipt(input),
                    icon: Icon(AppIcons.share, size: 16),
                    child: const Text('Bagikan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ThickBottomBorderButton(
                    variant: ThickButtonVariant.secondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    onPressed: () => _previewReceipt(input),
                    icon: Icon(AppIcons.eye, size: 16),
                    child: const Text('Pratinjau'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ThickBottomBorderButton(
              isFullWidth: true,
              variant: ThickButtonVariant.primary,
              onPressed: () => Navigator.pop(context),
              icon: Icon(AppIcons.checkCircle, size: 18),
              child: const Text('Transaksi Baru'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(AppRoutes.beranda);
              },
              child: Text(
                'Kembali ke Beranda',
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Checkout Execution (Zero Multiple-Charge Guarantee)
  // ---------------------------------------------------------------------------

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
      final customerId = _isWalkIn ? null : _selectedCustomer?.id;

      final itemsSnapshot = List<DirectSaleItemInput>.from(_items);
      final totalSnapshot = _total;

      final draft = DirectSaleDraft(
        customerId: customerId,
        items: itemsSnapshot,
        payMethod: _method,
        paidAmount: paid,
      );

      final result = await repo.checkout(draft);
      if (!mounted) return;

      // Ambil shop settings & printedBy
      String shopName = 'Bengkel';
      String? shopAddress;
      String? shopPhone;
      String? receiptNotes;
      try {
        final settings = ref.read(settingsProvider).valueOrNull;
        if (settings != null) {
          if (settings.shopName.isNotEmpty) shopName = settings.shopName;
          shopAddress = settings.address;
          shopPhone = settings.phone;
          receiptNotes = settings.receiptNotes;
        } else {
          final profile = ref.read(sessionProvider).valueOrNull;
          if (profile != null && profile.shopName?.isNotEmpty == true) {
            shopName = profile.shopName!;
          }
        }
      } catch (_) {}

      final printedBy =
          ref.read(sessionProvider).valueOrNull?.fullName.isNotEmpty == true
              ? ref.read(sessionProvider).valueOrNull!.fullName
              : ref.read(sessionProvider).valueOrNull?.username ?? 'Kasir';

      final input = _buildReceiptInput(
        saleNumber:
            result.saleNumber.isNotEmpty ? result.saleNumber : result.id,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        receiptNotes: receiptNotes,
        printedBy: printedBy,
        itemsSnapshot: itemsSnapshot,
        totalSnapshot: totalSnapshot,
      );

      // 1. TUTUP MODAL SHEET JIKA SEDANG TERBUKA
      Navigator.of(context).pop();

      // 2. RESET STATE KERANJANG SEKETIKA JADI 0 (ANTI MULTIPLE-CHARGE)
      _clearCart();
      setState(() => _saving = false);

      // 3. REFRESH INVENTORI & LAPORAN
      ref.invalidate(partListControllerProvider);
      try {
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(laporanDailySummariesProvider);
        ref.invalidate(topPartsProvider);
        ref.invalidate(ownerFinancialSummaryProvider);
      } catch (_) {}

      // 4. TAMPILKAN MODAL SUKSES DENGAN OPSI AMAN
      _showSuccessDialog(input);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Interactive Cart Sheet
  // ---------------------------------------------------------------------------

  void _openCartModal() {
    showNeoBottomSheet(
      context: context,
      title: 'Keranjang Belanja',
      child: StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pelanggan Selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.borderInk, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(AppIcons.user, size: 16, color: AppColors.ink900),
                          const SizedBox(width: 6),
                          Text(
                            'Pelanggan',
                            style: AppTypography.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      NeoSegmentControl<bool>(
                        selectedValue: _isWalkIn,
                        onValueChanged: (val) {
                          setModalState(() {
                            _isWalkIn = val;
                            if (val) _selectedCustomer = null;
                          });
                          setState(() {});
                        },
                        items: const [
                          NeoSegmentItem(
                            value: true,
                            label: 'Walk-in (Umum)',
                            activeColor: AppColors.pastelMint,
                          ),
                          NeoSegmentItem(
                            value: false,
                            label: 'Pilih Database',
                            activeColor: AppColors.pastelAmber,
                          ),
                        ],
                      ),
                      if (!_isWalkIn) ...[
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (c, refCust, _) {
                            final custRepo =
                                refCust.watch(customerRepositoryProvider);
                            return FutureBuilder<List<Customer>>(
                              future: custRepo.list(limit: 50),
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const LinearProgressIndicator();
                                }
                                final customers = snap.data ?? [];
                                if (customers.isEmpty) {
                                  return Text(
                                    'Belum ada data pelanggan di database',
                                    style: AppTypography.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                }
                                return DropdownButtonFormField<Customer>(
                                  initialValue: _selectedCustomer,
                                  isExpanded: true,
                                  hint: const Text('Pilih pelanggan'),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: customers
                                      .map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              '${c.name} (${c.phone ?? "-"})',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setModalState(
                                        () => _selectedCustomer = val);
                                    setState(() {});
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // List Items
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Keranjang masih kosong',
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: item.kind == WoItemKind.jasa
                                      ? AppColors.pastelAmber
                                      : AppColors.pastelMint,
                                  borderRadius: AppRadius.sm,
                                  border: Border.all(
                                    color: AppColors.borderInk,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  item.kind == WoItemKind.jasa
                                      ? AppIcons.wrench
                                      : AppIcons.inventory,
                                  size: 18,
                                  color: AppColors.ink900,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description ?? 'Item',
                                      style: AppTypography.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${rupiah(item.unitPrice)} x ${item.qty.toInt()} = ${rupiah(item.lineTotal)}',
                                      style: AppTypography.mono(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      AppIcons.minus,
                                      size: 16,
                                      color: AppColors.ink900,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        _updateItemQty(i, item.qty - 1);
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  Text(
                                    item.qty.toInt().toString(),
                                    style: AppTypography.mono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      AppIcons.add,
                                      size: 16,
                                      color: AppColors.ink900,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        _updateItemQty(i, item.qty + 1);
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      AppIcons.trash,
                                      size: 16,
                                      color: AppColors.statusDanger,
                                    ),
                                    onPressed: () {
                                      setModalState(() => _removeItem(i));
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // Metode Pembayaran
                Text(
                  'Metode Pembayaran',
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                NeoSegmentControl<PaymentMethod>(
                  selectedValue: _method,
                  onValueChanged: (v) {
                    setModalState(() => _method = v);
                    setState(() {});
                  },
                  items: PaymentMethod.values
                      .map((m) => NeoSegmentItem(
                            value: m,
                            label: m.label,
                            activeColor: AppColors.pastelMint,
                          ))
                      .toList(),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.statusDanger,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Total & Bayar Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      rupiah(_total),
                      style: AppTypography.chakra(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ThickBottomBorderButton(
                  isFullWidth: true,
                  isLoading: _saving,
                  onPressed: _items.isEmpty ? null : _checkout,
                  child: Text('Selesaikan & Bayar (${rupiah(_total)})'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final partsAsync = ref.watch(partListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: NeoAppBar(
        title: 'Penjualan Langsung',
        actions: [
          if (_items.isNotEmpty)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(AppIcons.inventory, color: AppColors.ink900),
                  onPressed: _openCartModal,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.statusDanger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_totalItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: partsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat katalog: $e')),
        data: (state) {
          final allParts = state.items;

          // Filter by search & category
          final query = _searchQuery.trim().toLowerCase();
          final filteredParts = allParts.where((p) {
            final matchSearch = query.isEmpty ||
                p.name.toLowerCase().contains(query) ||
                (p.code?.toLowerCase().contains(query) ?? false);
            return matchSearch;
          }).toList();

          return Column(
            children: [
              // Search & Scanner Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: NeoSearchBar(
                        controller: _searchController,
                        hintText: 'Cari nama atau kode part...',
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        onScanTap: () => _scanBarcode(allParts),
                        onClear: _searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Categories & Quick Jasa Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('Semua'),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Suku Cadang'),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Jasa'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ThickBottomBorderButton(
                      variant: ThickButtonVariant.secondary,
                      onPressed: _addJasaDialog,
                      icon: Icon(AppIcons.add, size: 14),
                      child: const Text('Jasa Custom'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Main Catalog Grid
              Expanded(
                child: _selectedCategory == 'Jasa'
                    ? _buildJasaOnlyView()
                    : filteredParts.isEmpty
                        ? Center(
                            child: EmptyState(
                              icon: AppIcons.inventory,
                              title: 'Suku cadang tidak ditemukan',
                              message:
                                  'Coba ubah kata kunci pencarian atau gunakan barcode.',
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.80,
                            ),
                            itemCount: filteredParts.length,
                            itemBuilder: (ctx, i) {
                              final part = filteredParts[i];
                              return _buildProductCard(part);
                            },
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _items.isEmpty
          ? const SizedBox.shrink()
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.borderInk, width: 2),
                  boxShadow: AppShadow.l2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.pastelMint,
                        borderRadius: AppRadius.button,
                        border:
                            Border.all(color: AppColors.borderInk, width: 1.5),
                        boxShadow: AppShadow.l1,
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(AppIcons.inventory,
                              size: 20, color: AppColors.ink900),
                          Positioned(
                            top: -6,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.statusDanger,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_totalItemCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total ($_totalItemCount item)',
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            rupiah(_total),
                            style: AppTypography.chakra(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ThickBottomBorderButton(
                      variant: ThickButtonVariant.primary,
                      onPressed: _openCartModal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Keranjang'),
                          const SizedBox(width: 4),
                          Icon(AppIcons.caretRight, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category Pill Widget
  // ---------------------------------------------------------------------------

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: AppRadius.button,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelMint : AppColors.canvas,
          borderRadius: AppRadius.button,
          border: Border.all(color: AppColors.borderInk, width: 1.5),
          boxShadow: isSelected ? AppShadow.l1 : null,
        ),
        child: Text(
          category,
          style: AppTypography.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.ink900,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Product Card in Grid
  // ---------------------------------------------------------------------------

  Widget _buildProductCard(Part part) {
    final inCartQty = _getPartQtyInCart(part.id);

    return NeoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Code & Stock Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: AppRadius.sm,
                    border: Border.all(color: AppColors.borderInk, width: 1),
                  ),
                  child: Text(
                    part.code ?? 'PART',
                    style: AppTypography.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: part.isOutOfStock
                      ? AppColors.canvas
                      : (part.isLowStock
                          ? AppColors.pastelAmber
                          : AppColors.pastelMint),
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: part.isOutOfStock
                        ? AppColors.statusDanger
                        : AppColors.borderInk,
                    width: 1,
                  ),
                ),
                child: Text(
                  part.isOutOfStock
                      ? 'Habis'
                      : (part.isLowStock
                          ? 'Sisa ${part.stockQty.toInt()}'
                          : 'Stok ${part.stockQty.toInt()}'),
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: part.isOutOfStock
                        ? AppColors.statusDanger
                        : AppColors.ink900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Name
          Expanded(
            child: Text(
              part.name,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),

          // Price
          Text(
            rupiah(part.sellPrice),
            style: AppTypography.chakra(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),

          // Action Button or Stepper
          if (part.isOutOfStock)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppRadius.button,
                border: Border.all(color: AppColors.borderHairline, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                'Stok Habis',
                style: AppTypography.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else if (inCartQty == 0)
            ThickBottomBorderButton(
              isFullWidth: true,
              variant: ThickButtonVariant.primary,
              onPressed: () => _incrementPart(part),
              icon: Icon(AppIcons.add, size: 14),
              child: const Text('Tambah'),
            )
          else
            // Tactile Stepper Row
            Container(
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppRadius.button,
                border: Border.all(color: AppColors.borderInk, width: 1.5),
                boxShadow: AppShadow.l1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _decrementPart(part),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Icon(AppIcons.minus,
                          size: 14, color: AppColors.ink900),
                    ),
                  ),
                  Text(
                    inCartQty.toInt().toString(),
                    style: AppTypography.mono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: inCartQty >= part.stockQty
                        ? null
                        : () => _incrementPart(part),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Icon(
                        AppIcons.add,
                        size: 14,
                        color: inCartQty >= part.stockQty
                            ? AppColors.textSecondary
                            : AppColors.ink900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Jasa Only View
  // ---------------------------------------------------------------------------

  Widget _buildJasaOnlyView() {
    final jasaItems = _items.where((e) => e.kind == WoItemKind.jasa).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.pastelAmber,
                    borderRadius: AppRadius.button,
                    border: Border.all(color: AppColors.borderInk, width: 1.5),
                    boxShadow: AppShadow.l1,
                  ),
                  alignment: Alignment.center,
                  child:
                      Icon(AppIcons.wrench, size: 24, color: AppColors.ink900),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jasa & Layanan Bengkel',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tambahkan jasa servis langsung dengan tarif kustom.',
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ThickBottomBorderButton(
            isFullWidth: true,
            variant: ThickButtonVariant.primary,
            onPressed: _addJasaDialog,
            icon: Icon(AppIcons.add, size: 16),
            child: const Text('Tambah Jasa Baru'),
          ),
          const SizedBox(height: 16),
          if (jasaItems.isNotEmpty) ...[
            Text(
              'Jasa di Keranjang:',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: jasaItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final j = jasaItems[i];
                  return NeoCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              j.description ?? 'Jasa',
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${j.qty.toInt()} x ${rupiah(j.unitPrice)}',
                              style: AppTypography.mono(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          rupiah(j.lineTotal),
                          style: AppTypography.chakra(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

