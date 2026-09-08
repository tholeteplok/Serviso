import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_filter_chip.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/admin_controllers.dart';
import '../models/admin_models.dart';
import 'create_shop_screen.dart';

class PlatformAdminScreen extends ConsumerStatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  ConsumerState<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends ConsumerState<PlatformAdminScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(platformSummaryProvider);
    ref.invalidate(platformShopsProvider);
  }

  Future<void> _createShop() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateShopScreen()),
    );
    if (created == true) {
      _refreshAll();
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showNeoConfirmDialog(
      context: context,
      title: 'Keluar Akun?',
      message: 'Anda akan keluar dari sesi Platform Admin.',
      confirmLabel: 'Keluar',
      isDanger: true,
    );
    if (confirm == true && mounted) {
      await ref.read(sessionProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(platformSummaryProvider);
    final shopsAsync = ref.watch(platformShopsProvider);
    final activeFilter = ref.watch(platformShopFilterStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: NeoAppBar(
        title: 'Platform Admin',
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh, color: AppColors.ink900),
            tooltip: 'Segarkan',
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: Icon(AppIcons.prohibit, color: AppColors.action),
            tooltip: 'Keluar',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.button,
          side: BorderSide(color: AppColors.borderInk, width: 1.5),
        ),
        onPressed: _createShop,
        icon: Icon(AppIcons.add, size: 20),
        label: const Text('Buat Toko Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummarySection(summaryAsync),
              const SizedBox(height: 20),
              _buildSearchAndFilters(activeFilter),
              const SizedBox(height: 16),
              _buildShopsList(shopsAsync),
              const SizedBox(height: 80), // bottom clearance for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(AsyncValue<PlatformSummary> summaryAsync) {
    return summaryAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => NeoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(AppIcons.warning, color: AppColors.action),
            const SizedBox(width: 8),
            Expanded(child: Text('Gagal memuat ringkasan: $err')),
          ],
        ),
      ),
      data: (summary) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Toko Aktif',
                    count: '${summary.activeShopsCount}',
                    bgColor: AppColors.pastelMint,
                    icon: AppIcons.storefront,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Toko Nonaktif',
                    count: '${summary.inactiveShopsCount}',
                    bgColor: AppColors.pastelPink,
                    icon: AppIcons.lock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Pengguna',
                    count: '${summary.totalUsersCount}',
                    bgColor: AppColors.pastelBlue,
                    icon: AppIcons.user,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Baru Bulan Ini',
                    count: '+${summary.newShopsThisMonthCount}',
                    bgColor: AppColors.pastelYellow,
                    icon: AppIcons.add,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderInk, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderInk,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
              Icon(icon, size: 18, color: AppColors.ink900),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool? activeFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeoTextField(
          controller: _searchCtrl,
          hintText: 'Cari nama atau kode toko...',
          prefixIcon: AppIcons.search,
          onChanged: (val) {
            ref.read(platformShopSearchQueryProvider.notifier).state = val;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            NeoFilterChip(
              label: 'Semua',
              isSelected: activeFilter == null,
              onTap: () {
                ref.read(platformShopFilterStatusProvider.notifier).state = null;
              },
            ),
            const SizedBox(width: 8),
            NeoFilterChip(
              label: 'Aktif',
              isSelected: activeFilter == true,
              activeColor: AppColors.pastelMint,
              onTap: () {
                ref.read(platformShopFilterStatusProvider.notifier).state = true;
              },
            ),
            const SizedBox(width: 8),
            NeoFilterChip(
              label: 'Nonaktif',
              isSelected: activeFilter == false,
              activeColor: AppColors.pastelPink,
              onTap: () {
                ref.read(platformShopFilterStatusProvider.notifier).state = false;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShopsList(AsyncValue<List<ShopItem>> shopsAsync) {
    return shopsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => NeoCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Gagal memuat daftar toko: $err',
          style: const TextStyle(color: AppColors.action),
        ),
      ),
      data: (shops) {
        if (shops.isEmpty) {
          return const NeoCard(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Tidak ada toko yang sesuai.',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shops.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final shop = shops[index];
            return NeoCard(
              onTap: () {
                context.push('${AppRoutes.platformAdmin}/toko/${shop.id}');
              },
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: shop.isActive ? AppColors.pastelMint : AppColors.pastelPink,
                                borderRadius: AppRadius.badge,
                                border: Border.all(color: AppColors.borderInk, width: 1.5),
                              ),
                              child: Text(
                                shop.isActive ? 'Aktif' : 'Nonaktif',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Kode: ${shop.slug}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              _formatDate(shop.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(AppIcons.caretRight, size: 20, color: AppColors.ink900),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
