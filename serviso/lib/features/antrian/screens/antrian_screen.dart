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

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final board = ref.watch(boardControllerProvider);
    final onlyToday = ref.watch(todayFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrian'),
        actions: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16),
              const SizedBox(width: 4),
              const Text('Hari ini'),
              Switch(
                value: !onlyToday,
                onChanged: (_) =>
                    ref.read(todayFilterProvider.notifier).state = !onlyToday,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Text('Semua'),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.woBaru),
        icon: const Icon(Icons.add),
        label: const Text('WO Baru'),
      ),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(boardControllerProvider),
        ),
        data: (orders) {
          final visible = onlyToday
              ? orders.where((o) => _isToday(o.createdAt)).toList()
              : orders;
          final grouped = {
            for (final status in _columns)
              status: visible.where((o) => o.status == status).toList(),
          };

          return RefreshIndicator(
            onRefresh: () => ref.refresh(boardControllerProvider.future),
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final status in _columns)
                          _BoardColumn(
                            status: status,
                            orders: grouped[status]!,
                            textTheme: textTheme,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.status,
    required this.orders,
    required this.textTheme,
  });

  final WoStatus status;
  final List<WorkOrder> orders;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: status.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  status.label,
                  style: textTheme.titleMedium?.copyWith(
                    color: status.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: textTheme.labelMedium?.copyWith(
                      color: status.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Belum ada work order',
                      message: 'Buat WO baru lewat tombol WO Baru.',
                    ),
                  )
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) => WoCard(
                      order: orders[index],
                      onTap: () => context.push(
                        '/antrian/${orders[index].id}',
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
