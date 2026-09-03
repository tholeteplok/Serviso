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
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_line_chart.dart';
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
      appBar: NeoAppBar(
        title: 'Serviso',
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(AppIcons.user, color: AppColors.ink900),
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
                  _UnifiedRevenueCard(revenue: summary.todayRevenue),
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
                  const SizedBox(height: 14),
                  _buildChartCard(context, summary.last7Days),
                  const SizedBox(height: 14),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ],
        ),
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
      child: NeoLineChart(
        points: rows.asMap().entries.map((e) {
          final date = e.value.date;
          return NeoLineChartPoint(
            x: e.key.toDouble(),
            y: e.value.revenue,
            label: '${date.day}/${date.month}',
            tooltipTitle: '${date.day}/${date.month}/${date.year}',
          );
        }).toList(),
        valueFormatter: (val) => rupiah(val),
        emptyTitle: 'Belum ada data transaksi',
        emptyMessage: 'Grafik tren pendapatan akan muncul otomatis.',
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Aksi Cepat',
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              context,
              icon: AppIcons.add,
              label: 'WO Baru',
              color: AppColors.pastelMint,
              onTap: () => context.push(AppRoutes.woBaru),
            ),
            _buildActionButton(
              context,
              icon: AppIcons.cart,
              label: 'Jual Langsung',
              color: AppColors.pastelYellow,
              onTap: () => context.push(AppRoutes.jualLangsung),
            ),
            _buildActionButton(
              context,
              icon: AppIcons.inventory,
              label: 'Inventori',
              color: AppColors.pastelBlue,
              onTap: () => context.go('/inventori'),
            ),
          ],
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.button,
                border: Border.all(color: AppColors.borderInk, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.borderInk,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.ink900, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedRevenueCard extends ConsumerWidget {
  const _UnifiedRevenueCard({required this.revenue});

  final double revenue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final async =
        ref.watch(dailyRevenueByMethodProvider((start: today, end: today)));

    final totals = <String, double>{'cash': 0, 'transfer': 0, 'qris': 0};
    final rows = async.valueOrNull;
    if (rows != null) {
      for (final r in rows) {
        final k = r.payMethod ?? 'cash';
        totals[k] = (totals[k] ?? 0) + r.revenue;
      }
    }

    return NeoCard(
      color: AppColors.pastelPurple,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.wallet,
                color: AppColors.ink900,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Pendapatan Hari Ini',
                style: AppTypography.inter(
                  color: AppColors.ink900,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rupiah(revenue),
            style: AppTypography.chakra(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppColors.borderInk.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMethodPill('Tunai', rupiah(totals['cash'] ?? 0)),
              const SizedBox(width: 8),
              _buildMethodPill('Transfer', rupiah(totals['transfer'] ?? 0)),
              const SizedBox(width: 8),
              _buildMethodPill('QRIS', rupiah(totals['qris'] ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: AppColors.borderInk.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTypography.chakra(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

