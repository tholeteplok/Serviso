import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadow.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../../auth/models/profile.dart';

const Map<UserRole, String> _roleLabels = {
  UserRole.admin: 'Pemilik (Admin)',
  UserRole.kasir: 'Kasir',
  UserRole.mekanik: 'Teknisi / Mekanik',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showNeoConfirmDialog(
      context: context,
      title: 'Keluar',
      message: 'Apakah Anda yakin ingin keluar dari akun ini?',
      confirmLabel: 'Keluar',
      isDanger: true,
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(sessionProvider.notifier).logout();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal keluar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    final profile = ref.watch(sessionProvider).valueOrNull;

    if (profile == null) {
      return const Scaffold(
        appBar: NeoAppBar(title: 'Pengaturan'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initial = profile.fullName.isNotEmpty
        ? profile.fullName[0].toUpperCase()
        : profile.username.isNotEmpty
            ? profile.username[0].toUpperCase()
            : 'U';

    return Scaffold(
      appBar: const NeoAppBar(title: 'Pengaturan'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Summary Card (Tappable -> /profil)
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderInk, width: 1.5),
              boxShadow: const [AppShadow.card],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.card,
                onTap: () => context.push(AppRoutes.profil),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.pastelMint,
                          border: Border.all(color: AppColors.borderInk, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName.isNotEmpty ? profile.fullName : profile.username,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${profile.username}',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.pastelCream,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.borderInk, width: 1),
                              ),
                              child: Text(
                                _roleLabels[profile.role] ?? 'Kasir',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(AppIcons.caretRight, size: 20, color: AppColors.inkMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Administrasi Section (Admin only)
          if (profile.isAdmin) ...[
            SectionCard(
              title: 'Administrasi',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.storefront),
                    title: const Text('Profil & Jenis Usaha Toko'),
                    subtitle: const Text('Nama, alamat, telepon & mode usaha'),
                    trailing: Icon(AppIcons.caretRight, size: 16),
                    onTap: () => context.push(AppRoutes.pengaturanToko),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.usersThree),
                    title: const Text('Kelola Pengguna'),
                    subtitle: const Text('Tambah kasir/admin & reset password'),
                    trailing: Icon(AppIcons.caretRight, size: 16),
                    onTap: () => context.push(AppRoutes.adminUsers),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.clipboardList),
                    title: const Text('Audit Log Sistem'),
                    subtitle: const Text('Riwayat aktivitas & transaksi'),
                    trailing: Icon(AppIcons.caretRight, size: 16),
                    onTap: () => context.push(AppRoutes.adminAuditLogs),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Platform Admin Section
          if (profile.isPlatformAdmin) ...[
            SectionCard(
              title: 'Platform Admin',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.shieldCheck),
                    title: const Text('Manajemen Toko'),
                    subtitle: const Text('Daftar & buat toko baru'),
                    trailing: Icon(AppIcons.caretRight, size: 16),
                    onTap: () => context.push(AppRoutes.platformAdmin),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Keluar (Logout Button)
          ThickBottomBorderButton(
            key: const Key('hub_logout_button'),
            variant: ThickButtonVariant.amber,
            isFullWidth: true,
            onPressed: () => _confirmLogout(context, ref),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.signOut, size: 20, color: AppColors.ink900),
                const SizedBox(width: 8),
                const Text('Keluar dari Akun'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
