import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/wo_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_search_bar.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/neo_switch.dart';
import '../../workorders/controllers/work_order_providers.dart';
import '../../workorders/models/work_order.dart';
import '../../workorders/widgets/continuous_ticket_card.dart';

class AntrianScreen extends ConsumerStatefulWidget {
  const AntrianScreen({super.key});

  @override
  ConsumerState<AntrianScreen> createState() => _AntrianScreenState();
}

class _AntrianScreenState extends ConsumerState<AntrianScreen> {
  final List<WoStatus> _columns = const [
    WoStatus.menunggu,
    WoStatus.dikerjakan,
    WoStatus.selesai,
  ];

  WoStatus _selectedStatus = WoStatus.menunggu;
  bool _searching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searching = false;
    });
  }

  bool _isToday(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(boardControllerProvider);
    final onlyToday = ref.watch(todayFilterProvider);

    return board.when(
      loading: () => const Scaffold(
        appBar: NeoAppBar(title: 'Antrian', showBack: false),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: const NeoAppBar(title: 'Antrian', showBack: false),
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(boardControllerProvider),
        ),
      ),
      data: (orders) {
        final dateFiltered = onlyToday
            ? orders.where((o) => _isToday(o.createdAt)).toList()
            : orders;

        final visible = _searchQuery.isEmpty
            ? dateFiltered
            : dateFiltered.where((o) {
                final q = _searchQuery.toLowerCase();
                return o.woNumber.toLowerCase().contains(q) ||
                    (o.plateNo?.toLowerCase().contains(q) ?? false) ||
                    (o.customerName?.toLowerCase().contains(q) ?? false) ||
                    (o.vehicleDesc?.toLowerCase().contains(q) ?? false) ||
                    (o.assignedName?.toLowerCase().contains(q) ?? false) ||
                    (o.complaint?.toLowerCase().contains(q) ?? false);
              }).toList();

        final grouped = {
          for (final status in _columns)
            status: visible.where((o) => o.status == status).toList(),
        };

        final segmentItems = [
          NeoSegmentItem<WoStatus>(
            value: WoStatus.menunggu,
            label: 'Menunggu',
            count: grouped[WoStatus.menunggu]?.length ?? 0,
            activeColor: AppColors.pastelYellow,
          ),
          NeoSegmentItem<WoStatus>(
            value: WoStatus.dikerjakan,
            label: 'Dikerjakan',
            count: grouped[WoStatus.dikerjakan]?.length ?? 0,
            activeColor: AppColors.pastelBlue,
          ),
          NeoSegmentItem<WoStatus>(
            value: WoStatus.selesai,
            label: 'Selesai',
            count: grouped[WoStatus.selesai]?.length ?? 0,
            activeColor: AppColors.pastelMint,
          ),
        ];

        return Scaffold(
          appBar: NeoAppBar(
            title: _searching ? null : 'Antrian',
            titleWidget: _searching
                ? NeoSearchBar(
                    controller: _searchController,
                    hintText: 'Cari plat, WO, pelanggan...',
                    onClear: _closeSearch,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                  )
                : null,
            showBack: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: NeoSegmentControl<WoStatus>(
                  selectedValue: _selectedStatus,
                  onValueChanged: (val) =>
                      setState(() => _selectedStatus = val),
                  items: segmentItems,
                ),
              ),
            ),
            actions: [
              if (!_searching) ...[
                IconButton(
                  icon: Icon(AppIcons.search),
                  tooltip: 'Cari work order',
                  onPressed: _openSearch,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hari ini',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight:
                              onlyToday ? FontWeight.bold : FontWeight.w500,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      NeoSwitch(
                        value: !onlyToday,
                        onChanged: (_) => ref
                            .read(todayFilterProvider.notifier)
                            .state = !onlyToday,
                        width: 48,
                        height: 26,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Semua',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight:
                              !onlyToday ? FontWeight.bold : FontWeight.w500,
                          color: AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          body: _StatusListTab(
            status: _selectedStatus,
            orders: grouped[_selectedStatus] ?? [],
            onRefresh: () => ref.refresh(boardControllerProvider.future),
          ),
        );
      },
    );
  }
}

class _StatusListTab extends StatelessWidget {
  const _StatusListTab({
    required this.status,
    required this.orders,
    required this.onRefresh,
  });

  final WoStatus status;
  final List<WorkOrder> orders;
  final Future<void> Function() onRefresh;

  Map<String, List<WorkOrder>> _groupByDay(List<WorkOrder> list) {
    final Map<String, List<WorkOrder>> map = {};
    for (final wo in list) {
      final d = wo.createdAt.toLocal();
      final dateKey =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(dateKey, () => []).add(wo);
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
    return '$dayName · $count SPK SELESAI$revenueStr';
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Tidak ada antrian ${status.label.toLowerCase()}',
                  message: 'Work order pada status ini akan tampil di sini.',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tab: Menunggu & Dikerjakan — Satu kartu tiket panjang berkesinambungan
    if (status != WoStatus.selesai) {
      final title = status == WoStatus.menunggu
          ? 'ANTREAN MENUNGGU · ${orders.length} SPK'
          : 'SEDANG DIKERJAKAN · ${orders.length} PIT AKTIF';

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ContinuousTicketCard(
              orders: orders,
              headerTitle: title,
              headerColor: status.bgColor,
              onOrderTap: (wo) => context.push('/antrian/${wo.id}'),
            ),
          ],
        ),
      );
    }

    // Tab: Selesai — Tiket panjang dipisah per hari
    final grouped = _groupByDay(orders);
    final sortedDateKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          for (final dateKey in sortedDateKeys) ...[
            Builder(
              builder: (context) {
                final dayOrders = grouped[dateKey]!;
                final firstDate = dayOrders.first.createdAt;
                final dayTotal = dayOrders.fold<double>(
                  0.0,
                  (sum, o) => sum + o.total,
                );
                return ContinuousTicketCard(
                  orders: dayOrders,
                  headerTitle:
                      _formatDateTitle(firstDate, dayOrders.length, dayTotal),
                  headerColor: AppColors.statusDone,
                  onOrderTap: (wo) => context.push('/antrian/${wo.id}'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
