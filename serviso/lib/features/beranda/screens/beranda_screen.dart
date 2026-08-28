import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
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
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil',
            onPressed: () => context.go('/profil'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          context,
                          title: 'WO Aktif',
                          value: '${summary.activeWoCount}',
                          unit: 'antrian',
                          icon: Icons.receipt_long_outlined,
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
                          icon: Icons.warning_amber_rounded,
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F512D6D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pendapatan Hari Ini',
                style: AppTypography.textTheme().bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
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
              color: Colors.white,
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
        ),
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
                          strokeColor: Colors.white,
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
            icon: Icons.add_task_rounded,
            label: 'WO Baru',
            color: AppColors.primary,
            onTap: () => context.go('/antrian'),
          ),
          _buildActionButton(
            context,
            icon: Icons.person_add_outlined,
            label: 'Pelanggan',
            color: AppColors.teal,
            onTap: () => context.go('/pelanggan'),
          ),
          _buildActionButton(
            context,
            icon: Icons.inventory_2_outlined,
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
      borderRadius: BorderRadius.circular(12),
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

FlLine _getHorizontalLine(double val) => const FlLine(
      color: AppColors.line,
      strokeWidth: 1,
    );

