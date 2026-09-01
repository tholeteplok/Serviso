import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/section_card.dart';
import '../../../features/auth/controllers/session_controller.dart';
import '../../../features/laporan/controllers/report_controllers.dart';
import '../../../features/laporan/models/report_models.dart';

class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    final profile = ref.watch(sessionProvider).valueOrNull;
    final dashboardAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviso'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.user),
            tooltip: 'Profil',
            onPressed: () => context.push(AppRoutes.profil),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(dailyRevenueByMethodProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (profile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${profile.fullName.isNotEmpty ? profile.fullName : profile.username}',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ringkasan operasional hari ini',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            dashboardAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(dashboardSummaryProvider),
              ),
              data: (summary) => Column(
                children: [
                  _buildRevenueCard(context, summary.todayRevenue),
                  const SizedBox(height: 8),
                  const _TodayMethodBreakdown(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          context,
                          title: 'WO Aktif',
                          value: '${summary.activeWoCount}',
                          unit: 'antrian',
                          icon: AppIcons.queue,
                          color: AppColors.teal,
                          onTap: () => context.go('/antrian'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          context,
                          title: 'Stok Menipis',
                          value: '${summary.lowStockCount}',
                          unit: 'suku cadang',
                          icon: AppIcons.warning,
                          color: summary.lowStockCount > 0
                              ? AppColors.action
                              : AppColors.inkMuted,
                          onTap: () => context.go('/inventori'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(context, summary.last7Days),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context, double revenue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pastelPurple,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderInk, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderInk,
            offset: Offset(0, 3.5),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.wallet,
                color: AppColors.ink900,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pendapatan Hari Ini',
                style: AppTypography.inter(
                  color: AppColors.ink900,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rupiah(revenue),
            style: AppTypography.chakra(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NeoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.textTheme().bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.chakra(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTypography.textTheme().bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<DailySummaryRow> rows) {
    return SectionCard(
      title: 'Tren Pendapatan 7 Hari',
      child: SizedBox(
        height: 180,
        child: rows.isEmpty
            ? Center(
                child: Text(
                  'Belum ada data transaksi',
                  style: AppTypography.textTheme().bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              )
            : LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: _getHorizontalLine,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          final date = rows[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: AppTypography.mono(
                                fontSize: 10,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: rows.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.revenue);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.teal,
                          strokeWidth: 2,
                          strokeColor: AppColors.bgSurface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return SectionCard(
      title: 'Aksi Cepat',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context,
            icon: AppIcons.add,
            label: 'WO Baru',
            color: AppColors.primary,
            onTap: () => context.push(AppRoutes.woBaru),
          ),
          _buildActionButton(
            context,
            icon: AppIcons.user,
            label: 'Pelanggan',
            color: AppColors.teal,
            onTap: () => context.push(AppRoutes.pelanggan),
          ),
          _buildActionButton(
            context,
            icon: AppIcons.inventory,
            label: 'Inventori',
            color: AppColors.ink,
            onTap: () => context.go('/inventori'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.button,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.textTheme().bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMethodBreakdown extends ConsumerWidget {
  const _TodayMethodBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final async = ref.watch(dailyRevenueByMethodProvider((start: today, end: today)));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.action, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Gagal muat metode: ${err.toString().replaceFirst('Exception: ', '')}',
                style: AppTypography.textTheme().labelSmall?.copyWith(color: AppColors.action),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(dailyRevenueByMethodProvider),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Coba'),
            ),
          ],
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final totals = <String, double>{'cash': 0, 'transfer': 0, 'qris': 0};
        for (final r in rows) {
          final k = r.payMethod ?? 'cash';
          totals[k] = (totals[k] ?? 0) + r.revenue;
        }
        if (totals.values.every((v) => v == 0)) return const SizedBox.shrink();
        return Row(
          children: [
            _miniMethodChip('Tunai', rupiah(totals['cash'] ?? 0), AppColors.pastelMint),
            const SizedBox(width: 8),
            _miniMethodChip('Transfer', rupiah(totals['transfer'] ?? 0), AppColors.pastelBlue),
            const SizedBox(width: 8),
            _miniMethodChip('QRIS', rupiah(totals['qris'] ?? 0), AppColors.pastelYellow),
          ],
        );
      },
    );
  }

  Widget _miniMethodChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: AppRadius.button,
          border: Border.all(color: AppColors.borderStrong, width: 1.5),
        ),
        child: Column(
          children: [
            Text(label, style: AppTypography.textTheme().labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}

FlLine _getHorizontalLine(double val) => const FlLine(
      color: AppColors.line,
      strokeWidth: 1,
    );

