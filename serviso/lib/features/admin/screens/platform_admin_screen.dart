import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/admin_controllers.dart';
import '../models/admin_models.dart';

class PlatformAdminScreen extends ConsumerStatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  ConsumerState<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends ConsumerState<PlatformAdminScreen> {
  final _searchCtrl = TextEditingController();
  bool _isCreatingShop = false;

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
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    final bool? result = await showNeoDialog<bool>(
      context: context,
      child: NeoDialog.alert(
        title: 'Buat Toko Baru',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeoTextField(
                controller: nameCtrl,
                labelText: 'Nama Toko (ex: Serviso Pusat)',
                prefixIcon: AppIcons.storefront,
              ),
              const SizedBox(height: 12),
              NeoTextField(
                controller: slugCtrl,
                labelText: 'Kode Toko (ex: serviso)',
                prefixIcon: AppIcons.tag,
              ),
              const SizedBox(height: 12),
              NeoTextField(
                controller: fullNameCtrl,
                labelText: 'Nama Lengkap Pemilik',
                prefixIcon: AppIcons.user,
              ),
              const SizedBox(height: 12),
              NeoTextField(
                controller: usernameCtrl,
                labelText: 'Username Pemilik (ex: admin)',
                prefixIcon: AppIcons.user,
              ),
              const SizedBox(height: 12),
              NeoTextField(
                controller: passwordCtrl,
                labelText: 'Password Pemilik (min 6 karakter)',
                prefixIcon: AppIcons.lock,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ThickBottomBorderButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buat'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    final shopName = nameCtrl.text.trim();
    final shopSlug = slugCtrl.text.trim().toLowerCase();
    final ownerFullName = fullNameCtrl.text.trim();
    final ownerUsername = usernameCtrl.text.trim().toLowerCase();
    final ownerPassword = passwordCtrl.text.trim();

    if (shopName.isEmpty ||
        shopSlug.isEmpty ||
        ownerFullName.isEmpty ||
        ownerUsername.isEmpty ||
        ownerPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi.')),
      );
      return;
    }

    if (ownerPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password pemilik minimal 6 karakter.')),
      );
      return;
    }

    setState(() => _isCreatingShop = true);
    try {
      final client = Supabase.instance.client;
      try {
        final session = client.auth.currentSession;
        if (session != null && session.isExpired) {
          await client.auth.refreshSession();
        }
      } catch (_) {}
      final token = client.auth.currentSession?.accessToken;
      final res = await client.functions.invoke(
        'create-shop',
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        body: {
          'shop_name': shopName,
          'shop_slug': shopSlug,
          'owner_full_name': ownerFullName,
          'owner_username': ownerUsername,
          'owner_password': ownerPassword,
        },
      );
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Toko dan owner berhasil dibuat!')),
          );
        }
        _refreshAll();
      } else {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal membuat toko.';
        throw Exception(errorMsg ?? 'Gagal membuat toko.');
      }
    } on FunctionException catch (fe) {
      if (mounted) {
        final details = fe.details;
        String? msg;
        if (details is Map) {
          msg = details['error']?.toString() ?? details['message']?.toString();
        } else if (details is String && details.isNotEmpty) {
          msg = details;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg ?? fe.reasonPhrase ?? 'Gagal membuat toko (${fe.status}).'),
            backgroundColor: AppColors.action,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.action,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingShop = false);
      }
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
        onPressed: _isCreatingShop ? null : _createShop,
        icon: _isCreatingShop
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(AppIcons.add, size: 20),
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
            _buildFilterChip(
              label: 'Semua',
              isSelected: activeFilter == null,
              onTap: () {
                ref.read(platformShopFilterStatusProvider.notifier).state = null;
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Aktif',
              isSelected: activeFilter == true,
              activeColor: AppColors.pastelMint,
              onTap: () {
                ref.read(platformShopFilterStatusProvider.notifier).state = true;
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color activeColor = AppColors.pastelYellow,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.badge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.bgSurface,
          borderRadius: AppRadius.badge,
          border: Border.all(color: AppColors.borderInk, width: 1.5),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.borderInk,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: AppColors.ink900,
          ),
        ),
      ),
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
