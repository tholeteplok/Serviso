import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/wo_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../workorders/controllers/work_order_providers.dart';
import '../../workorders/models/work_order.dart';
import '../../workorders/widgets/wo_card.dart';
import '../../../core/router/app_router.dart';

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
    final textTheme = AppTypography.textTheme();
    final board = ref.watch(boardControllerProvider);
    final onlyToday = ref.watch(todayFilterProvider);

    return board.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Antrian')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Antrian')),
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

        return DefaultTabController(
          length: _columns.length,
          child: Scaffold(
            appBar: AppBar(
              title: _searching
                  ? SearchBar(
                      controller: _searchController,
                      hintText: 'Cari plat, WO, pelanggan...',
                      hintStyle: WidgetStateProperty.all(
                        textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      leading: const Icon(Icons.search, size: 20),
                      trailing: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Tutup',
                          onPressed: _closeSearch,
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.trim()),
                      autoFocus: true,
                    )
                  : const Text('Antrian'),
              bottom: TabBar(
                isScrollable: false,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.inkMuted,
                tabs: [
                  for (final status in _columns)
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(status.label),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: status.bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${grouped[status]?.length ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                if (!_searching) ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Cari work order',
                    onPressed: _openSearch,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 4),
                      const Text('Hari ini'),
                      Switch(
                        value: !onlyToday,
                        onChanged: (_) => ref
                            .read(todayFilterProvider.notifier)
                            .state = !onlyToday,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('Semua'),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.woBaru),
              icon: const Icon(Icons.add),
              label: const Text('WO Baru'),
            ),
            body: TabBarView(
              children: [
                for (final status in _columns)
                  _StatusListTab(
                    status: status,
                    orders: grouped[status]!,
                    onRefresh: () =>
                        ref.refresh(boardControllerProvider.future),
                  ),
              ],
            ),
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => WoCard(
          order: orders[index],
          onTap: () => context.push(
            '/antrian/${orders[index].id}',
          ),
        ),
      ),
    );
  }
}
