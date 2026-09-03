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
import '../../../../core/widgets/plate_chip.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';
import '../../pdf/laporan_export.dart';

final woDoneDetailPeriodProvider =
    StateProvider<LaporanPeriod>((ref) => LaporanPeriod.days7);

({DateTime start, DateTime end}) _woDoneRange(LaporanPeriod period) {
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

class WoDoneDetailScreen extends ConsumerWidget {
  const WoDoneDetailScreen({super.key});

  Future<void> _handleExport(
    BuildContext context,
    List<WoDoneRow> rows,
    String periodLabel,
    String type,
  ) async {
    try {
      if (type == 'pdf') {
        final bytes = await buildWoDonePdf(
          rows: rows,
          periodLabel: periodLabel,
          exportedAt: DateTime.now(),
        );
        final name =
            'laporan_wo_selesai_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildWoDoneCsv(rows);
        final name =
            'laporan_wo_selesai_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF WO Selesai berhasil diekspor'
                  : 'CSV WO Selesai berhasil diekspor',
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
    final period = ref.watch(woDoneDetailPeriodProvider);
    final range = _woDoneRange(period);
    final periodLabel = period.label;
    final asyncRows = ref
        .watch(woDoneDetailProvider((start: range.start, end: range.end)));
    final rowsForExport = asyncRows.valueOrNull ?? const <WoDoneRow>[];

    return Scaffold(
      appBar: NeoAppBar(
        title: 'Rincian WO Selesai',
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
                  ref.read(woDoneDetailPeriodProvider.notifier).state = p,
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
                  woDoneDetailProvider((start: range.start, end: range.end)),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 32),
                      EmptyState(
                        icon: AppIcons.checkCircle,
                        title: 'Belum Ada WO Selesai',
                        message:
                            'Tidak ada work order selesai pada periode ini. Coba ganti periode.',
                      ),
                    ],
                  );
                }

                final totalRevenue =
                    rows.fold<double>(0, (s, r) => s + r.paidAmount);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Summary
                    NeoCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total WO',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${rows.length} WO',
                                  style: AppTypography.mono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
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
                                  'Total Pendapatan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rupiah(totalRevenue),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.mono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'dari WO selesai',
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
                    ...rows.map(
                      (r) => NeoCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        onTap: () => context.push('/antrian/${r.id}'),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (r.plateNo != null &&
                                          r.plateNo!.isNotEmpty)
                                        PlateChip(plateText: r.plateNo!)
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.canvas,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.inkMuted,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            '-',
                                            style: AppTypography.mono(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          r.woNumber,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.mono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    r.customerName ?? '-',
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
                                    '${dateShortId(r.completedAt)} • ${r.itemCount} item • ${_payMethodLabel(r.payMethod)}',
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
                                  rupiah(r.paidAmount),
                                  style: AppTypography.mono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _payMethodBg(r.payMethod),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.borderStrong, width: 1),
                                  ),
                                  child: Text(
                                    _payMethodLabel(r.payMethod),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          color: AppColors.ink,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.inkMuted,
                                ),
                              ],
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

String _payMethodLabel(String? value) {
  switch (value) {
    case 'transfer':
      return 'Transfer';
    case 'qris':
      return 'QRIS';
    case 'cash':
      return 'Tunai';
    default:
      return 'Belum Bayar';
  }
}

Color _payMethodBg(String? value) {
  switch (value) {
    case 'transfer':
      return AppColors.pastelBlue;
    case 'qris':
      return AppColors.pastelYellow;
    case 'cash':
      return AppColors.pastelMint;
    default:
      return AppColors.borderHairline;
  }
}
