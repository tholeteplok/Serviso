import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../../laporan/controllers/report_controllers.dart';
import '../../laporan/models/report_models.dart';
import '../../laporan/pdf/laporan_export.dart';
import '../../settings/data/settings_repository.dart';
import '../../workorders/models/payment.dart';
import '../../workorders/models/work_order.dart';
import '../../workorders/pdf/receipt_builder.dart';
import '../data/hold_transaction_service.dart';
import '../widgets/continuous_sale_ticket_card.dart';

({DateTime start, DateTime end}) _retailSaleRange(LaporanPeriod period) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case LaporanPeriod.days7:
      return (start: today.subtract(const Duration(days: 6)), end: today);
    case LaporanPeriod.days30:
      return (start: today.subtract(const Duration(days: 29)), end: today);
    case LaporanPeriod.thisMonth:
      return (start: DateTime(now.year, now.month, 1), end: today);
  }
}

class RetailSalesScreen extends ConsumerStatefulWidget {
  const RetailSalesScreen({super.key});

  @override
  ConsumerState<RetailSalesScreen> createState() => _RetailSalesScreenState();
}

class _RetailSalesScreenState extends ConsumerState<RetailSalesScreen> {
  int _selectedTabIndex = 0; // 0: Tertunda, 1: Selesai

  Map<String, List<DirectSaleReportRow>> _groupByDay(
      List<DirectSaleReportRow> list) {
    final Map<String, List<DirectSaleReportRow>> map = {};
    for (final sale in list) {
      final d = sale.paidAt.toLocal();
      final dateKey =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(dateKey, () => []).add(sale);
    }
    return map;
  }

  String _formatDateTitle(DateTime date, int count, double totalRevenue) {
    final d = date.toLocal();
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final isYesterday =
        d.year == now.year && d.month == now.month && d.day == now.day - 1;

    final dayName = isToday
        ? 'HARI INI'
        : (isYesterday
            ? 'KEMARIN'
            : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}');
    final revenueStr =
        totalRevenue > 0 ? ' · Total ${rupiah(totalRevenue)}' : '';
    return '$dayName · $count PENJUALAN$revenueStr';
  }

  Future<void> _handleExport(
    BuildContext context,
    List<DirectSaleReportRow> rows,
    String periodLabel,
    String type,
  ) async {
    try {
      if (type == 'pdf') {
        final bytes = await buildDirectSaleReportPdf(
          rows: rows,
          periodLabel: periodLabel,
          exportedAt: DateTime.now(),
        );
        final name =
            'laporan_penjualan_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildDirectSaleReportCsv(rows);
        final name =
            'laporan_penjualan_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF Penjualan berhasil diekspor'
                  : 'CSV Penjualan berhasil diekspor',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e')),
        );
      }
    }
  }

  Future<void> _reprintReceipt(
    BuildContext context,
    WidgetRef ref,
    DirectSaleReportRow sale,
  ) async {
    try {
      String shopName = 'Toko';
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

      final input = ReceiptInput(
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        receiptNotes: receiptNotes,
        woNumber: sale.saleNumber,
        plate: 'Penjualan Langsung',
        vehicleDesc: null,
        customerName: sale.customerName,
        items: sale.items
            .map((e) => WoItem(
                  id: e.partName ?? e.description,
                  kind: e.kind == 'part' ? WoItemKind.part : WoItemKind.jasa,
                  description: e.description,
                  qty: e.qty,
                  unitPrice: e.unitPrice,
                  discount: e.discount,
                ))
            .toList(),
        total: sale.paidAmount,
        payMethod: PaymentMethodX.fromValue(sale.payMethod).label,
        paidAmount: sale.paidAmount,
        printedBy: printedBy,
        printedAt: DateTime.now(),
      );

      final res = await buildReceiptPdf(input);
      await Printing.sharePdf(bytes: res.bytes, filename: res.filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak struk: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteDraft(BuildContext context, HoldSaleDraft draft) async {
    final confirmed = await showNeoConfirmDialog(
      context: context,
      title: 'Hapus Transaksi Tertunda',
      message:
          'Yakin ingin menghapus transaksi tertunda untuk "${draft.customerName ?? 'Pelanggan Umum'}"?\nTotal: ${rupiah(draft.total)}',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      ref.read(holdDraftsProvider.notifier).deleteDraft(draft.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi tertunda berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(holdDraftsProvider);

    return Scaffold(
      appBar: NeoAppBar(
        title: 'Penjualan',
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(AppIcons.add, color: AppColors.ink900),
            tooltip: 'Kasir Baru',
            onPressed: () => context.push(AppRoutes.jualLangsung),
          ),
          if (_selectedTabIndex == 1)
            Consumer(
              builder: (ctx, ref, _) {
                final period = ref.watch(directSalesDetailPeriodProvider);
                final range = _retailSaleRange(period);
                final rows = ref
                        .watch(directSalesDetailProvider(
                            (start: range.start, end: range.end)))
                        .valueOrNull ??
                    const <DirectSaleReportRow>[];
                return PopupMenuButton<String>(
                  tooltip: 'Export',
                  onSelected: (value) =>
                      _handleExport(ctx, rows, period.label, value),
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                    PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                  ],
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: NeoSegmentControl<int>(
              selectedValue: _selectedTabIndex,
              onValueChanged: (idx) => setState(() => _selectedTabIndex = idx),
              items: [
                NeoSegmentItem<int>(
                  value: 0,
                  label: drafts.isNotEmpty
                      ? 'Tertunda (${drafts.length})'
                      : 'Tertunda',
                ),
                const NeoSegmentItem<int>(
                  value: 1,
                  label: 'Selesai',
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildDraftsTab(drafts)
                : _buildCompletedTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsTab(List<HoldSaleDraft> drafts) {
    if (drafts.isEmpty) {
      return EmptyState(
        icon: AppIcons.clock,
        title: 'Tidak Ada Transaksi Tertunda',
        message:
            'Transaksi yang ditunda saat pelanggan masih memilih barang atau antre akan tersimpan di sini.',
        actionLabel: 'Buka Kasir',
        onAction: () => context.push(AppRoutes.jualLangsung),
      );
    }

    final timeFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final draft = drafts[index];
        final itemCount = draft.items.fold<int>(0, (sum, i) => sum + i.qty.toInt());

        return NeoCard(
          margin: const EdgeInsets.only(bottom: 12),
          headerColor: AppColors.pastelYellow,
          header: Row(
            children: [
              Icon(AppIcons.clock, size: 16, color: AppColors.ink900),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  draft.customerName ?? 'Pelanggan Umum',
                  style: AppTypography.kalam(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeFormatter.format(draft.createdAt),
                style: AppTypography.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Items preview
              Text(
                'Ringkasan Pesanan ($itemCount item):',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 6),
              ...draft.items.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.description ?? 'Barang',
                          style: AppTypography.inter(
                            fontSize: 13,
                            color: AppColors.ink900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.qty.toInt()}x  ${rupiah(item.lineTotal)}',
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (draft.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text(
                    '+ ${draft.items.length - 3} item lainnya...',
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const Divider(height: 20, color: AppColors.borderInk),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL BELANJA',
                        style: AppTypography.inter(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        rupiah(draft.total),
                        style: AppTypography.kalam(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(AppIcons.trash, color: AppColors.statusDanger),
                        tooltip: 'Hapus Draft',
                        onPressed: () => _confirmDeleteDraft(context, draft),
                      ),
                      const SizedBox(width: 4),
                      ThickBottomBorderButton(
                        size: ThickButtonSize.compact,
                        variant: ThickButtonVariant.primary,
                        onPressed: () {
                          context.push(AppRoutes.jualLangsung, extra: draft);
                        },
                        icon: Icon(AppIcons.cart, size: 14),
                        child: const Text('Lanjutkan'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    final period = ref.watch(directSalesDetailPeriodProvider);
    final range = _retailSaleRange(period);
    final asyncRows = ref.watch(
      directSalesDetailProvider((start: range.start, end: range.end)),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: NeoSegmentControl<LaporanPeriod>(
            selectedValue: period,
            onValueChanged: (p) =>
                ref.read(directSalesDetailPeriodProvider.notifier).state = p,
            items: LaporanPeriod.values
                .map((p) => NeoSegmentItem<LaporanPeriod>(
                      value: p,
                      label: p.label,
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: asyncRows.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorView(
              message: 'Gagal memuat riwayat penjualan: $err',
              onRetry: () => ref.invalidate(directSalesDetailProvider),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyState(
                  icon: AppIcons.receipt,
                  title: 'Belum Ada Penjualan Selesai',
                  message:
                      'Transaksi yang diselesaikan di kasir pada periode ini akan muncul di sini.',
                );
              }

              final totalCount = rows.length;
              final totalRevenue =
                  rows.fold<double>(0.0, (sum, r) => sum + r.paidAmount);

              final grouped = _groupByDay(rows);
              final sortedKeys = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  NeoCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'TOTAL TRANSAKSI',
                              style: AppTypography.inter(
                                fontSize: 11,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalCount Transaksi',
                              style: AppTypography.kalam(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1.5,
                          height: 36,
                          color: AppColors.borderInk,
                        ),
                        Column(
                          children: [
                            Text(
                              'TOTAL OMSET',
                              style: AppTypography.inter(
                                fontSize: 11,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rupiah(totalRevenue),
                              style: AppTypography.kalam(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  for (final key in sortedKeys) ...[
                    Builder(builder: (context) {
                      final dayRows = grouped[key]!;
                      final dayTotal = dayRows.fold<double>(
                          0.0, (sum, r) => sum + r.paidAmount);
                      final firstDate = dayRows.first.paidAt;

                      return ContinuousSaleTicketCard(
                        headerTitle: _formatDateTitle(
                          firstDate,
                          dayRows.length,
                          dayTotal,
                        ),
                        sales: dayRows,
                        onReprint: (sale) =>
                            _reprintReceipt(context, ref, sale),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
