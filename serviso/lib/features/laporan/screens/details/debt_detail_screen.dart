import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

enum DebtFilter {
  unpaid('Belum Lunas'),
  paid('Lunas');

  final String label;
  const DebtFilter(this.label);
}

final debtFilterProvider = StateProvider<DebtFilter>((ref) => DebtFilter.unpaid);

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key});

  Future<void> _handleExport(
    BuildContext context,
    List<DistributorDebtItem> rows,
    String periodLabel,
    String type,
  ) async {
    try {
      if (type == 'pdf') {
        final bytes = await buildDebtPdf(
          rows: rows,
          periodLabel: periodLabel,
          exportedAt: DateTime.now(),
        );
        final name =
            'laporan_hutang_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
        await sharePdfBytes(bytes, name);
      } else {
        final csv = buildDebtCsv(rows);
        final name =
            'laporan_hutang_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
        await shareCsv(csv, name);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'pdf'
                  ? 'PDF Hutang berhasil diekspor'
                  : 'CSV Hutang berhasil diekspor',
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

  Future<void> _handleMarkPaid(
    BuildContext context,
    WidgetRef ref,
    DistributorDebtItem debt,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pelunasan Hutang'),
        content: Text(
          'Konfirmasi pelunasan hutang ke "${debt.distributor}" sebesar ${rupiah(debt.totalDebt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Lunasi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(reportRepositoryProvider).markDebtPaid(debt.movementId);
      ref.invalidate(distributorDebtsProvider);
      ref.invalidate(ownerFinancialSummaryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hutang distributor berhasil dilunasi')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rincian Hutang')),
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

    final filter = ref.watch(debtFilterProvider);
    final asyncDebts = ref.watch(distributorDebtsProvider);

    // Filtered rows for export – computed lazily after data loads
    List<DistributorDebtItem> filteredForExport(
        List<DistributorDebtItem> all) {
      return all.where((d) {
        final status = d.debtStatus.toLowerCase();
        if (filter == DebtFilter.paid) {
          return status == 'lunas';
        }
        return status == 'belum_lunas';
      }).toList();
    }

    final periodLabel = filter.label;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Hutang'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export',
            onSelected: (value) {
              final all = asyncDebts.valueOrNull ?? const <DistributorDebtItem>[];
              final filtered = filteredForExport(all);
              _handleExport(context, filtered, periodLabel, value);
            },
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
            child: NeoSegmentControl<DebtFilter>(
              selectedValue: filter,
              onValueChanged: (f) =>
                  ref.read(debtFilterProvider.notifier).state = f,
              activeColor: AppColors.pastelMint,
              items: DebtFilter.values
                  .map((f) => NeoSegmentItem<DebtFilter>(
                        value: f,
                        label: f.label,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncDebts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(distributorDebtsProvider),
              ),
              data: (allDebts) {
                final filtered = filteredForExport(allDebts);

                if (filter == DebtFilter.paid && filtered.isEmpty) {
                  // Still show summary with 0 + empty state for paid tab
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      const _DebtSummaryCard(
                        totalDebt: 0,
                        distributorCount: 0,
                        itemCount: 0,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 32),
                      const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'Tidak ada hutang lunas',
                        message:
                            'Belum ada hutang yang dilunasi. Data hutang lunas akan tampil di sini.',
                      ),
                    ],
                  );
                }

                if (filtered.isEmpty) {
                  // unpaid empty
                  final totalDebt = filtered.fold<double>(
                      0, (s, d) => s + d.totalDebt);
                  final distributorCount =
                      filtered.map((e) => e.distributor).toSet().length;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _DebtSummaryCard(
                        totalDebt: totalDebt,
                        distributorCount: distributorCount,
                        itemCount: filtered.length,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 32),
                      const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'Tidak ada hutang',
                        message:
                            'Tidak ada hutang distributor yang belum lunas. Semua kewajiban telah terbayar!',
                      ),
                    ],
                  );
                }

                final totalDebt =
                    filtered.fold<double>(0, (s, d) => s + d.totalDebt);
                final distributorCount =
                    filtered.map((e) => e.distributor).toSet().length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _DebtSummaryCard(
                      totalDebt: totalDebt,
                      distributorCount: distributorCount,
                      itemCount: filtered.length,
                    ),
                    const SizedBox(height: 16),
                    ...filtered.map((d) => _DebtItemCard(
                          debt: d,
                          filter: filter,
                          onPay: () => _handleMarkPaid(context, ref, d),
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

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({
    required this.totalDebt,
    required this.distributorCount,
    required this.itemCount,
  });

  final double totalDebt;
  final int distributorCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Hutang',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(totalDebt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: totalDebt > 0 ? AppColors.action : AppColors.teal,
                  ),
                ),
                Text(
                  '$itemCount item',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.borderHairline),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distributor',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '$distributorCount',
                  style: AppTypography.mono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'pihak terkait',
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
    );
  }
}

class _DebtItemCard extends StatelessWidget {
  const _DebtItemCard({
    required this.debt,
    required this.filter,
    required this.onPay,
  });

  final DistributorDebtItem debt;
  final DebtFilter filter;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final isPastDue = debt.dueDate != null &&
        debt.dueDate!
            .isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final isUnpaid = debt.debtStatus.toLowerCase() == 'belum_lunas';
    final showPayButton = isUnpaid && filter == DebtFilter.unpaid;

    return NeoCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor:
          isPastDue && isUnpaid ? AppColors.statusCancelled : AppColors.borderStrong,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPastDue && isUnpaid
                  ? AppColors.action.withValues(alpha: 0.12)
                  : AppColors.inkMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: isPastDue && isUnpaid ? AppColors.action : AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.distributor,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${debt.partName} • ${debt.qty.toStringAsFixed(debt.qty == debt.qty.roundToDouble() ? 0 : 1)} pcs',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                if (debt.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Jatuh Tempo: ${dateShortId(debt.dueDate!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isPastDue && isUnpaid
                              ? AppColors.action
                              : AppColors.inkMuted,
                          fontWeight:
                              isPastDue && isUnpaid ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUnpaid ? AppColors.pastelPink : AppColors.pastelMint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderStrong, width: 1),
                  ),
                  child: Text(
                    isUnpaid ? 'Belum Lunas' : 'Lunas',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rupiah(debt.totalDebt),
                style: AppTypography.mono(
                  fontWeight: FontWeight.bold,
                  color: isUnpaid ? AppColors.action : AppColors.teal,
                  fontSize: 14,
                ),
              ),
              if (showPayButton) ...[
                const SizedBox(height: 6),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onPay,
                  child: const Text('Lunasi'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
