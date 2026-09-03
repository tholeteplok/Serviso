import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/neo_app_bar.dart';
import '../../../../core/widgets/neo_bar_chart.dart';
import '../../../../core/widgets/neo_bottom_sheet.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_segment_control.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/transaction_card.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';
import '../../pdf/laporan_export.dart';

final omsetDetailPeriodProvider =
    StateProvider<LaporanPeriod>((ref) => LaporanPeriod.days7);

final omsetDetailRowsProvider = FutureProvider.autoDispose
    .family<List<DailySummaryRow>, ({DateTime start, DateTime end})>(
        (ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.fetchDailySummaries(start: range.start, end: range.end);
});

({DateTime start, DateTime end}) _omsetRange(LaporanPeriod period) {
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

class OmsetDetailScreen extends ConsumerWidget {
  const OmsetDetailScreen({super.key});

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    List<DailySummaryRow> rows,
    String periodLabel,
    String type,
  ) async {
    try {
      if (type == 'pdf') {
        final bytes = await buildOmsetPdf(
          rows: rows,
          periodLabel: periodLabel,
          exportedAt: DateTime.now(),
        );
        final name =
            'laporan_omset_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildOmsetCsv(rows);
        final name =
            'laporan_omset_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF Omset berhasil diekspor'
                  : 'CSV Omset berhasil diekspor',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(omsetDetailPeriodProvider);
    final range = _omsetRange(period);
    final periodLabel = period.label;
    final asyncRows =
        ref.watch(omsetDetailRowsProvider((start: range.start, end: range.end)));
    final asyncMethodRows =
        ref.watch(dailyRevenueByMethodProvider((start: range.start, end: range.end)));

    final rowsForExport = asyncRows.valueOrNull ?? <DailySummaryRow>[];

    return Scaffold(
      appBar: NeoAppBar(
        title: 'Rincian Omset',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export',
            onSelected: (value) =>
                _handleExport(context, ref, rowsForExport, periodLabel, value),
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
                  ref.read(omsetDetailPeriodProvider.notifier).state = p,
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
                  omsetDetailRowsProvider((start: range.start, end: range.end)),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 32),
                      EmptyState(
                        icon: AppIcons.report,
                        title: 'Belum Ada Data Omset',
                        message:
                            'Tidak ada transaksi pada periode ini. Coba ganti periode atau tunggu transaksi selesai.',
                      ),
                    ],
                  );
                }

                final totalRevenue =
                    rows.fold<double>(0, (s, r) => s + r.revenue);
                final avgRevenue =
                    rows.isEmpty ? 0.0 : totalRevenue / rows.length;
                final maxRow = rows.reduce(
                    (a, b) => a.revenue >= b.revenue ? a : b);
                // Filter newest: tampilkan hari terbaru di atas
                final displayRows = List<DailySummaryRow>.from(rows)
                  ..sort((a, b) => b.date.compareTo(a.date));
                // Kelompokkan revenue per metode per tanggal
                final methodRows = asyncMethodRows.valueOrNull ?? [];
                final methodByDate = <String, Map<String, double>>{};
                for (final m in methodRows) {
                  final k = m.date.toIso8601String().substring(0, 10);
                  methodByDate.putIfAbsent(k, () => {})[m.payMethod ?? 'cash'] = m.revenue;
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Ringkasan 3 kartu
                    Row(
                      children: [
                        Expanded(
                          child: _SmallSummaryCard(
                            title: 'Total',
                            value: rupiah(totalRevenue),
                            subtitle: '${rows.length} hari',
                            color: AppColors.primary,
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SmallSummaryCard(
                            title: 'Rata-rata',
                            value: rupiah(avgRevenue),
                            subtitle: 'per hari',
                            color: AppColors.teal,
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SmallSummaryCard(
                            title: 'Tertinggi',
                            value: rupiah(maxRow.revenue),
                            subtitle: dateShortId(maxRow.date),
                            color: AppColors.ink,
                            icon: Icons.emoji_events_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Grafik (tetap kronologis agar tren mudah dibaca)
                    SectionCard(
                      title: 'Grafik Pendapatan Harian',
                      child: NeoBarChart(
                        items: rows.map((r) {
                          final d = r.date;
                          return NeoBarChartItem(
                            label: '${d.day}/${d.month}',
                            value: r.revenue,
                            tooltipTitle: '${d.day}/${d.month}/${d.year}',
                            tooltipSubtitle: '${r.woDoneCount} WO • ${r.directSaleCount} PL',
                          );
                        }).toList(),
                        valueFormatter: (val) => rupiah(val),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rincian Harian (Terbaru di atas)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...displayRows.map((r) => NeoCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          onTap: () => _showDayTransactions(context, ref, r.date),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateShortId(r.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r.woDoneCount} WO + ${r.directSaleCount} PL • ${r.partsOutQty.toStringAsFixed(0)} pcs part',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.inkMuted),
                                    ),
                                    Builder(builder: (_) {
                                      final key = r.date.toIso8601String().substring(0, 10);
                                      final map = methodByDate[key];
                                      if (map == null || map.isEmpty) return const SizedBox.shrink();
                                      String label(String m) {
                                        switch (m) {
                                          case 'transfer':
                                            return 'Transfer';
                                          case 'qris':
                                            return 'QRIS';
                                          default:
                                            return 'Tunai';
                                        }
                                      }
                                      Color bg(String m) {
                                        switch (m) {
                                          case 'transfer':
                                            return AppColors.pastelBlue;
                                          case 'qris':
                                            return AppColors.pastelYellow;
                                          default:
                                            return AppColors.pastelMint;
                                        }
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: map.entries.map((e) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: bg(e.key).withValues(alpha: 0.35),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.borderStrong, width: 1),
                                              ),
                                              child: Text(
                                                '${label(e.key)} ${rupiah(e.value)}',
                                                style: AppTypography.mono(fontSize: 9, fontWeight: FontWeight.w600),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    rupiah(r.revenue),
                                    style: AppTypography.mono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.inkMuted,
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  void _showDayTransactions(BuildContext context, WidgetRef ref, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    showNeoBottomSheet(
      context: context,
      title: 'Transaksi ${dateShortId(date)}',
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Consumer(
          builder: (ctx, ref2, _) {
            final async = ref2.watch(transactionsProvider((start: start, end: end)));
            return async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref2.invalidate(transactionsProvider((start: start, end: end)))),
              data: (rows) {
                if (rows.isEmpty) {
                  return EmptyState(
                      icon: AppIcons.receipt,
                      title: 'Tidak ada transaksi',
                      message: 'Tidak ada WO maupun Penjualan Langsung pada tanggal ini.');
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => TransactionCard(row: rows[i]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SmallSummaryCard extends StatelessWidget {
  const _SmallSummaryCard({
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
