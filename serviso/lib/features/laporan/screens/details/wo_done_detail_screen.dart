import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/neo_app_bar.dart';
import '../../../../core/widgets/neo_bottom_sheet.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../../../core/widgets/neo_search_bar.dart';
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

class WoDoneDetailScreen extends ConsumerStatefulWidget {
  const WoDoneDetailScreen({super.key});

  @override
  ConsumerState<WoDoneDetailScreen> createState() => _WoDoneDetailScreenState();
}

class _WoDoneDetailScreenState extends ConsumerState<WoDoneDetailScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _searchController.text = ref.read(woDoneSearchProvider);
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(woDoneSearchProvider.notifier).state = '';
    setState(() => _searching = false);
  }

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

  void _showSortSheet(BuildContext context, WoDoneSortOption currentSort) {
    showNeoBottomSheet(
      context: context,
      title: 'Urutkan WO Selesai',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final opt in WoDoneSortOption.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                opt.label,
                style: AppTypography.textTheme().bodyMedium?.copyWith(
                      fontWeight: opt == currentSort
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: opt == currentSort
                          ? AppColors.ink900
                          : AppColors.textSecondary,
                    ),
              ),
              leading: Icon(
                opt == currentSort
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: opt == currentSort
                    ? AppColors.ink900
                    : AppColors.borderHairline,
                size: 20,
              ),
              onTap: () {
                ref.read(woDoneSortProvider.notifier).state = opt;
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(woDoneDetailPeriodProvider);
    final range = _woDoneRange(period);
    final periodLabel = period.label;
    final asyncFiltered = ref.watch(filteredWoDoneDetailProvider(range));
    final currentMethodFilter = ref.watch(woDoneMethodFilterProvider);
    final currentSort = ref.watch(woDoneSortProvider);
    final rowsForExport = asyncFiltered.valueOrNull ?? const <WoDoneRow>[];

    return Scaffold(
      appBar: NeoAppBar(
        title: _searching ? '' : 'Rincian WO Selesai',
        bottom: _searching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: NeoSearchBar(
                    controller: _searchController,
                    hintText: 'Cari plat, nomor WO, pelanggan...',
                    autofocus: true,
                    onChanged: (val) =>
                        ref.read(woDoneSearchProvider.notifier).state = val,
                    onClear: _closeSearch,
                  ),
                ),
              )
            : null,
        actions: [
          if (!_searching)
            IconButton(
              icon: Icon(AppIcons.search, color: AppColors.ink900),
              tooltip: 'Cari WO Selesai',
              onPressed: _openSearch,
            ),
          PopupMenuButton<String>(
            tooltip: 'Export',
            icon: Icon(AppIcons.share, color: AppColors.ink900),
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
              items: LaporanPeriod.values
                  .map((p) => NeoSegmentItem<LaporanPeriod>(
                        value: p,
                        label: p.label,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: WoPayMethodFilter.values.map((method) {
                        final isSelected = currentMethodFilter == method;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => ref
                                .read(woDoneMethodFilterProvider.notifier)
                                .state = method,
                            borderRadius: AppRadius.badge,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.ink900
                                    : AppColors.bgSurface,
                                borderRadius: AppRadius.badge,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.ink900
                                      : AppColors.borderHairline,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                method.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.bgSurface
                                          : AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showSortSheet(context, currentSort),
                  borderRadius: AppRadius.badge,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppRadius.badge,
                      border: Border.all(
                        color: AppColors.borderHairline,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.filter,
                          size: 14,
                          color: AppColors.ink900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Urutkan',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncFiltered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(
                  woDoneDetailProvider((start: range.start, end: range.end)),
                ),
              ),
              data: (rows) {
                final rawAsync = ref.watch(woDoneDetailProvider(range));
                final isRawEmpty = rawAsync.valueOrNull?.isEmpty ?? false;

                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 32),
                      EmptyState(
                        icon: isRawEmpty ? AppIcons.checkCircle : AppIcons.search,
                        title: isRawEmpty
                            ? 'Belum Ada WO Selesai'
                            : 'Tidak Ditemukan',
                        message: isRawEmpty
                            ? 'Tidak ada work order selesai pada periode ini. Coba ganti periode.'
                            : 'Tidak ada WO selesai yang cocok dengan pencarian atau filter.',
                      ),
                    ],
                  );
                }

                final totalRevenue =
                    rows.fold<double>(0, (s, r) => s + r.paidAmount);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Summary Card
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
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${rows.length} WO',
                                  style: AppTypography.mono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentMethodFilter != WoPayMethodFilter.all
                                      ? '$periodLabel • ${currentMethodFilter.label}'
                                      : periodLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.textSecondary),
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
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rupiah(totalRevenue),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.mono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentMethodFilter != WoPayMethodFilter.all
                                      ? 'dari ${currentMethodFilter.label}'
                                      : 'dari WO selesai',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.textSecondary),
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
                                            color: AppColors.bgSurface,
                                            borderRadius: AppRadius.chipSmall,
                                            border: Border.all(
                                              color: AppColors.borderHairline,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            '-',
                                            style: AppTypography.mono(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.ink900,
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
                                            color: AppColors.ink900,
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
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink900,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      if (r.vehicleDesc != null &&
                                          r.vehicleDesc!.isNotEmpty)
                                        r.vehicleDesc!,
                                      dateShortId(r.completedAt),
                                      '${r.itemCount} item',
                                      _payMethodLabel(r.payMethod),
                                    ].join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.textSecondary),
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
                                    color: AppColors.ink900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _payMethodBg(r.payMethod),
                                    borderRadius: AppRadius.badge,
                                    border: Border.all(
                                        color: AppColors.borderStrong, width: 1),
                                  ),
                                  child: Text(
                                    _payMethodLabel(r.payMethod),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          color: AppColors.ink900,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
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
