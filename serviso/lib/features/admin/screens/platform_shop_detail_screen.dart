import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/models/profile.dart';
import '../controllers/admin_controllers.dart';
import '../models/admin_models.dart';

class PlatformShopDetailScreen extends ConsumerStatefulWidget {
  final String shopId;

  const PlatformShopDetailScreen({
    super.key,
    required this.shopId,
  });

  @override
  ConsumerState<PlatformShopDetailScreen> createState() => _PlatformShopDetailScreenState();
}

class _PlatformShopDetailScreenState extends ConsumerState<PlatformShopDetailScreen> {
  bool _isActionLoading = false;

  Future<void> _toggleShopStatus(ShopItem shop) async {
    final willDeactivate = shop.isActive;
    final confirmed = await showNeoConfirmDialog(
      context: context,
      title: willDeactivate ? 'Nonaktifkan Toko?' : 'Aktifkan Toko?',
      message: willDeactivate
          ? 'Toko "${shop.name}" akan dinonaktifkan. Seluruh akun di toko ini tidak akan dapat login, dan seluruh akses data akan dikunci di database.'
          : 'Toko "${shop.name}" akan diaktifkan kembali. Pengguna toko dapat kembali login dan beroperasi normal.',
      confirmLabel: willDeactivate ? 'Ya, Nonaktifkan' : 'Ya, Aktifkan',
      isDanger: willDeactivate,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.setShopActive(widget.shopId, !willDeactivate);

      ref.invalidate(platformShopDetailProvider(widget.shopId));
      ref.invalidate(platformShopsProvider);
      ref.invalidate(platformSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willDeactivate
                  ? 'Toko "${shop.name}" berhasil dinonaktifkan.'
                  : 'Toko "${shop.name}" berhasil diaktifkan kembali.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: AppColors.action,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(platformShopDetailProvider(widget.shopId));
    final usersAsync = ref.watch(platformShopUsersProvider(widget.shopId));
    final statsAsync = ref.watch(platformShopStatsProvider(widget.shopId));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: NeoAppBar(
        title: 'Detail Toko',
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh, color: AppColors.ink900),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.invalidate(platformShopDetailProvider(widget.shopId));
              ref.invalidate(platformShopUsersProvider(widget.shopId));
              ref.invalidate(platformShopStatsProvider(widget.shopId));
            },
          ),
        ],
      ),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.warning, size: 48, color: AppColors.action),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat detail toko: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ThickBottomBorderButton(
                  onPressed: () => ref.invalidate(platformShopDetailProvider(widget.shopId)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (shop) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(platformShopDetailProvider(widget.shopId));
              ref.invalidate(platformShopUsersProvider(widget.shopId));
              ref.invalidate(platformShopStatsProvider(widget.shopId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentityCard(shop),
                  const SizedBox(height: 16),
                  _buildStatsCard(statsAsync),
                  const SizedBox(height: 16),
                  _buildStatusActionCard(shop),
                  const SizedBox(height: 24),
                  _buildUsersSection(usersAsync),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIdentityCard(ShopItem shop) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: shop.isActive ? AppColors.pastelMint : AppColors.pastelPink,
                  borderRadius: AppRadius.badge,
                  border: Border.all(color: AppColors.borderInk, width: 1.5),
                ),
                child: Text(
                  shop.isActive ? 'Aktif' : 'Nonaktif',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(AppIcons.tag, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Kode Toko: ${shop.slug}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(AppIcons.calendar, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Terdaftar: ${_formatDate(shop.createdAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (shop.phone != null && shop.phone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(AppIcons.phone, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  shop.phone!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          if (shop.address != null && shop.address!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(AppIcons.mapPin, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shop.address!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<ShopStats> statsAsync) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.report, size: 18, color: AppColors.ink900),
              const SizedBox(width: 8),
              const Text(
                'Aktivitas Toko',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Gagal memuat statistik: $err',
              style: const TextStyle(fontSize: 12, color: AppColors.action),
            ),
            data: (stats) {
              return Row(
                children: [
                  Expanded(
                    child: _buildMiniStatTile(
                      label: 'Work Order',
                      value: '${stats.totalWorkOrders}',
                      bgColor: AppColors.pastelYellow,
                      icon: AppIcons.wrench,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatTile(
                      label: 'Pelanggan',
                      value: '${stats.totalCustomers}',
                      bgColor: AppColors.pastelBlue,
                      icon: AppIcons.user,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatTile(
                      label: 'Penjualan',
                      value: '${stats.totalDirectSales}',
                      bgColor: AppColors.pastelMint,
                      icon: AppIcons.receipt,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatTile({
    required String label,
    required String value,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.button,
        border: Border.all(color: AppColors.borderInk, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.ink900),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActionCard(ShopItem shop) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.isActive ? 'Tindakan Keamanan & Akses' : 'Pemulihan Akses Toko',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            shop.isActive
                ? 'Menonaktifkan toko akan mencabut hak login semua pengguna dan memblokir akses data di database.'
                : 'Mengaktifkan toko akan mengembalikan hak akses pengguna untuk login dan bertransaksi kembali.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ThickBottomBorderButton(
            isFullWidth: true,
            isLoading: _isActionLoading,
            variant: shop.isActive ? ThickButtonVariant.danger : ThickButtonVariant.primary,
            icon: Icon(
              shop.isActive ? AppIcons.lock : AppIcons.checkCircle,
              size: 18,
            ),
            onPressed: _isActionLoading ? null : () => _toggleShopStatus(shop),
            child: Text(
              shop.isActive ? 'Nonaktifkan Toko Ini' : 'Aktifkan Kembali Toko Ini',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection(AsyncValue<List<Profile>> usersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.user, size: 18, color: AppColors.ink900),
            const SizedBox(width: 8),
            const Text(
              'Pengguna Toko',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            const Spacer(),
            usersAsync.maybeWhen(
              data: (users) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.pastelPurple,
                  borderRadius: AppRadius.badge,
                  border: Border.all(color: AppColors.borderInk, width: 1.5),
                ),
                child: Text(
                  '${users.length} Orang',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        usersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => NeoCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gagal memuat pengguna: $err',
              style: const TextStyle(color: AppColors.action),
            ),
          ),
          data: (users) {
            if (users.isEmpty) {
              return const NeoCard(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Belum ada pengguna terdaftar pada toko ini.'),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                return NeoCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.pastelBlue,
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.ink900,
                              ),
                            ),
                            Text(
                              '@${user.username}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: user.isAdmin ? AppColors.pastelYellow : AppColors.bgSurface,
                          borderRadius: AppRadius.badge,
                          border: Border.all(color: AppColors.borderInk, width: 1.5),
                        ),
                        child: Text(
                          userRoleLabel[user.role] ?? 'Kasir',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
