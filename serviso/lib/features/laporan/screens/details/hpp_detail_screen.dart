import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_segment_control.dart';
import '../../../auth/controllers/session_controller.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';
import '../../pdf/laporan_export.dart';

final hppDetailPeriodProvider =
    StateProvider<LaporanPeriod>((ref) => LaporanPeriod.days7);

({DateTime start, DateTime end}) _hppRange(LaporanPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case LaporanPeriod.days7:
      return (start: now.subtract(const Duration(days: 6)), end: now);
    case LaporanPeriod.days30:
      return (start: now.subtract(const Duration(days: 29)), end: now);
    case LaporanPeriod.thisMonth:
      return (start: DateTime(now.year, now.month, 1), end: now);
  }
}

class HppDetailScreen extends ConsumerWidget {
  const HppDetailScreen({super.key});

  Future<void> _handleExport(
    BuildContext context,
    List<HppRow> rows,
    String periodLabel,
    String type,
  ) async {
    try {
      if (type == 'pdf') {
        final bytes = await buildHppPdf(
          rows: rows,
          periodLabel: periodLabel,
          exportedAt: DateTime.now(),
        );
        final name =
            'laporan_hpp_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildHppCsv(rows);
        final name =
            'laporan_hpp_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF HPP berhasil diekspor'
                  : 'CSV HPP berhasil diekspor',
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
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rincian HPP')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.lock,
              title: 'Akses Terbatas',
              message:
                  'Hanya pemilik dapat melihat rincian laba bersih. Hubungi pemilik bengkel.',
              actionLabel: 'Kembali',
              onAction: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    }

    final period = ref.watch(hppDetailPeriodProvider);
    final range = _hppRange(period);
    final periodLabel = period.label;
    final asyncRows =
        ref.watch(hppDetailProvider((start: range.start, end: range.end)));
    final rowsForExport = asyncRows.valueOrNull ?? const <HppRow>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian HPP'),
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
                  ref.read(hppDetailPeriodProvider.notifier).state = p,
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
                  hppDetailProvider((start: range.start, end: range.end)),
                ),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 32),
                      EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Belum Ada Data HPP',
                        message: 'Tidak ada data HPP pada periode ini',
                      ),
                    ],
                  );
                }

                final totalHpp =
                    rows.fold<double>(0, (s, r) => s + r.totalCogs);
                final count = rows.length;
                final avgHpp = count == 0 ? 0.0 : totalHpp / count;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _HppSummaryCard(
                            title: 'Total HPP',
                            value: rupiah(totalHpp),
                            subtitle: '$count WO',
                            color: AppColors.primary,
                            icon: Icons.inventory_2_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HppSummaryCard(
                            title: 'Jumlah WO',
                            value: '$count WO',
                            subtitle: periodLabel,
                            color: AppColors.teal,
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HppSummaryCard(
                            title: 'Rata-rata',
                            value: rupiah(avgHpp),
                            subtitle: 'per WO',
                            color: AppColors.ink,
                            icon: Icons.calculate_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rincian per WO',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...rows.map(
                      (r) => NeoCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        onTap: () => context.push('/antrian/${r.woId}'),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
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
                                    r.woNumber,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.mono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dateShortId(r.completedAt)} • ${r.itemCount} item',
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
                                  rupiah(r.totalCogs),
                                  style: AppTypography.mono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
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

class _HppSummaryCard extends StatelessWidget {
  const _HppSummaryCard({
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
