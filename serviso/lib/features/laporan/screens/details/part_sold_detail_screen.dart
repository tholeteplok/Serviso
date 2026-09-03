import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/neo_app_bar.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_segment_control.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';
import '../../pdf/laporan_export.dart';

final partSoldPeriodProvider =
    StateProvider<LaporanPeriod>((ref) => LaporanPeriod.days7);

({DateTime start, DateTime end}) _partSoldRange(LaporanPeriod period) {
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

class PartSoldDetailScreen extends ConsumerWidget {
  const PartSoldDetailScreen({super.key});

  Future<void> _handleExport(
    BuildContext context,
    List<PartSoldDetailRow> rows,
    String periodLabel,
    String type,
  ) async {
    try {
      if (type == 'pdf') {
        final bytes = await buildPartSoldPdf(
          rows: rows,
          periodLabel: periodLabel,
          exportedAt: DateTime.now(),
        );
        final name =
            'laporan_part_terjual_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildPartSoldCsv(rows);
        final name =
            'laporan_part_terjual_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF Part Terjual berhasil diekspor'
                  : 'CSV Part Terjual berhasil diekspor',
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
    final period = ref.watch(partSoldPeriodProvider);
    final range = _partSoldRange(period);
    final periodLabel = period.label;
    final asyncRows = ref
        .watch(partsSoldDetailProvider((start: range.start, end: range.end)));
    final rowsForExport = asyncRows.valueOrNull ?? const <PartSoldDetailRow>[];

    return Scaffold(
      appBar: NeoAppBar(
        title: 'Rincian Part Terjual',
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
                  ref.read(partSoldPeriodProvider.notifier).state = p,
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(
                  partsSoldDetailProvider(
                      (start: range.start, end: range.end)),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 32),
                      EmptyState(
                        icon: AppIcons.part,
                        title: 'Belum Ada Part Terjual',
                        message:
                            'Tidak ada penjualan part pada periode ini. Coba ganti periode.',
                      ),
                    ],
                  );
                }

                // Ensure sorted by qtyOut desc (repo already does)
                final sorted = [...rows]
                  ..sort((a, b) => b.qtyOut.compareTo(a.qtyOut));
                final totalQty =
                    sorted.fold<double>(0, (s, r) => s + r.qtyOut);
                final totalRev =
                    sorted.fold<double>(0, (s, r) => s + r.revenue);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    NeoCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Item',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${totalQty.toStringAsFixed(0)} pcs',
                                  style: AppTypography.mono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${sorted.length} jenis part',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: AppColors.borderHairline,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Revenue',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rupiah(totalRev),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.mono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  periodLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...sorted.map(
                      (r) => NeoCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        onTap: () => context.push('/inventori/${r.partId}'),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.qtyOut.toStringAsFixed(0)} pcs terjual',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  rupiah(r.revenue),
                                  style: AppTypography.mono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.qtyOut == 0
                                      ? '-'
                                      : '${rupiah(r.revenue / r.qtyOut)} /pcs',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.inkMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
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
