import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/neo_app_bar.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_segment_control.dart';
import '../../../auth/controllers/session_controller.dart';
import '../../../settings/data/settings_repository.dart';
import '../../../workorders/models/payment.dart';
import '../../../workorders/models/work_order.dart';
import '../../../workorders/pdf/receipt_builder.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';
import '../../pdf/laporan_export.dart';

({DateTime start, DateTime end}) _directSaleRange(LaporanPeriod period) {
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

class DirectSaleDetailScreen extends ConsumerWidget {
  const DirectSaleDetailScreen({super.key});

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
            'laporan_penjualan_langsung_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildDirectSaleReportCsv(rows);
        final name =
            'laporan_penjualan_langsung_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF Penjualan Langsung berhasil diekspor'
                  : 'CSV Penjualan Langsung berhasil diekspor',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(directSalesDetailPeriodProvider);
    final range = _directSaleRange(period);
    final periodLabel = period.label;
    final asyncRows = ref.watch(
      directSalesDetailProvider((start: range.start, end: range.end)),
    );
    final rowsForExport =
        asyncRows.valueOrNull ?? const <DirectSaleReportRow>[];

    return Scaffold(
      appBar: NeoAppBar(
        title: 'Rincian Penjualan Langsung',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export',
            onSelected: (value) =>
                _handleExport(context, rowsForExport, periodLabel, value),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: NeoSegmentControl<LaporanPeriod>(
              selectedValue: period,
              onValueChanged: (p) =>
                  ref.read(directSalesDetailPeriodProvider.notifier).state = p,
              activeColor: AppColors.pastelMint,
              items: LaporanPeriod.values
                  .map((p) => NeoSegmentItem<LaporanPeriod>(
                        value: p,
                        label: p.label,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncRows.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(
                  directSalesDetailProvider(
                    (start: range.start, end: range.end),
                  ),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 32),
                      EmptyState(
                        icon: AppIcons.money,
                        title: 'Belum Ada Penjualan Langsung',
                        message:
                            'Tidak ada transaksi penjualan langsung pada periode ini.',
                      ),
                    ],
                  );
                }

                final totalAmount =
                    rows.fold<double>(0, (s, r) => s + r.paidAmount);
                final totalItems =
                    rows.fold<int>(0, (s, r) => s + r.itemCount);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Top Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Penjualan',
                            value: rupiah(totalAmount),
                            subtitle: '${rows.length} transaksi',
                            color: AppColors.pastelMint,
                            icon: AppIcons.wallet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Transaksi',
                            value: '${rows.length}',
                            subtitle: 'Penjualan cepat',
                            color: AppColors.pastelBlue,
                            icon: AppIcons.receipt,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Item Terjual',
                            value: '$totalItems Pcs',
                            subtitle: 'Part & jasa',
                            color: AppColors.pastelYellow,
                            icon: AppIcons.inventory,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section Title
                    Text(
                      'Riwayat Transaksi (${rows.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Transaction Cards
                    ...rows.map((sale) => _DirectSaleCard(
                          sale: sale,
                          onReprint: () => _reprintReceipt(context, ref, sale),
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.badge,
                  border: Border.all(color: AppColors.borderInk, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 12, color: AppColors.ink900),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

class _DirectSaleCard extends StatefulWidget {
  const _DirectSaleCard({
    required this.sale,
    required this.onReprint,
  });

  final DirectSaleReportRow sale;
  final VoidCallback onReprint;

  @override
  State<_DirectSaleCard> createState() => _DirectSaleCardState();
}

class _DirectSaleCardState extends State<_DirectSaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final payMethod = PaymentMethodX.fromValue(sale.payMethod);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeoCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header (Number + Date + Payment Method Badge)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.saleNumber,
                        style: AppTypography.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateTimeId(sale.paidAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.pastelMint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderStrong, width: 1),
                  ),
                  child: Text(
                    payMethod.label,
                    style: AppTypography.textTheme().labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Customer info + Total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sale.customerName?.isNotEmpty == true
                      ? 'Pelanggan: ${sale.customerName}'
                      : 'Pelanggan: Umum',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
                Text(
                  rupiah(sale.paidAmount),
                  style: AppTypography.mono(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),

            if (sale.items.isNotEmpty) ...[
              const Divider(height: 16),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sale.items.length} Rincian Item',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Icon(
                      _expanded
                          ? AppIcons.caretUp
                          : AppIcons.caretDown,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 6),
                ...sale.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                              ),
                              Text(
                                '${item.qty.toStringAsFixed(0)} x ${rupiah(item.unitPrice)}${item.discount > 0 ? ' (diskon -${rupiah(item.discount)})' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          rupiah(item.subtotal),
                          style: AppTypography.mono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onReprint,
                icon: Icon(AppIcons.share, size: 14, color: AppColors.ink900),
                label: const Text('Cetak / Bagikan Struk',
                    style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.ink,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
