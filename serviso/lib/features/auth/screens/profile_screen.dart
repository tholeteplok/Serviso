import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_shadow.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_brand_icon.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../controllers/session_controller.dart';
import '../data/auth_repository.dart';
import '../models/profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(sessionProvider).valueOrNull;
    _nameController.text = profile?.fullName ?? '';
    _phoneController.text = profile?.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      setState(() => _editing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e is AuthException ? e.message : 'Profil gagal diperbarui.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showNeoConfirmDialog(
      context: context,
      title: 'Keluar',
      message: 'Apakah Anda yakin ingin keluar dari akun ini?',
      confirmLabel: 'Keluar',
      isDanger: true,
    );
    if (confirm != true) return;
    await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final profile = ref.watch(sessionProvider).valueOrNull;

    return Scaffold(
      appBar: const NeoAppBar(
        title: 'Profil',
        showBack: false,
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pastelMint,
                      border: Border.all(color: AppColors.borderInk, width: 2),
                      boxShadow: AppShadow.l1,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : profile.username[0].toUpperCase(),
                      style: AppTypography.chakra(
                        fontSize: 32,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    profile.fullName.isNotEmpty ? profile.fullName : profile.username,
                    style: textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '@${profile.username}',
                    style: AppTypography.mono(color: AppColors.inkMuted),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.pastelMint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderStrong, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.borderStrong,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      userRoleLabel[profile.role] ?? 'Kasir',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Data akun',
                  trailing: _editing
                      ? null
                      : TextButton.icon(
                          onPressed: () => setState(() => _editing = true),
                          icon: Icon(AppIcons.edit, size: 16),
                          label: const Text('Ubah'),
                        ),
                  child: Column(
                    children: [
                      _FieldRow(
                        label: 'Kode Toko',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pastelMint,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.borderStrong,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                profile.shopSlug?.isNotEmpty == true
                                    ? profile.shopSlug!
                                    : (profile.shopName?.isNotEmpty == true
                                        ? profile.shopName!
                                        : '-'),
                                style: AppTypography.mono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                            if (profile.shopSlug?.isNotEmpty == true) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                key: const Key('copy_shop_slug'),
                                icon: Icon(
                                  AppIcons.copy,
                                  size: 18,
                                  color: AppColors.ink900,
                                ),
                                tooltip: 'Salin Kode Toko',
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: profile.shopSlug!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kode toko berhasil disalin'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (profile.shopName?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _FieldRow(
                          label: 'Nama Toko',
                          child: Text(
                            profile.shopName!,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _FieldRow(
                        label: 'Nama lengkap',
                        child: _editing
                            ? NeoTextField(
                                controller: _nameController,
                                hintText: 'Nama lengkap',
                              )
                            : Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName
                                    : '-',
                                style: textTheme.bodyLarge,
                              ),
                      ),
                      const SizedBox(height: 12),
                      _FieldRow(
                        label: 'Telepon',
                        child: _editing
                            ? NeoTextField(
                                controller: _phoneController,
                                hintText: 'Nomor telepon',
                                keyboardType: TextInputType.phone,
                              )
                            : Text(
                                profile.phone?.isNotEmpty == true
                                    ? profile.phone!
                                    : '-',
                                style: textTheme.bodyLarge,
                              ),
                      ),
                      const SizedBox(height: 12),
                      _FieldRow(
                        label: 'Email pemulihan',
                        child: Text(
                          profile.email?.isNotEmpty == true ? profile.email! : '-',
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 16),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.statusDanger),
                            ),
                          ),
                        ThickBottomBorderButton(
                          isFullWidth: true,
                          isLoading: _saving,
                          onPressed: _saving ? null : _save,
                          child: const Text('Simpan'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (profile.isAdmin) ...[
                  SectionCard(
                    title: 'Administrasi',
                    child: Column(
                      children: [
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
                        const Divider(height: 1, color: AppColors.line),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(AppIcons.storefront),
                          title: const Text('Pengaturan Toko'),
                          subtitle: const Text('Nama, alamat, telepon'),
                          trailing: Icon(AppIcons.caretRight, size: 16),
                          onTap: () => context.push(AppRoutes.pengaturan),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                ThickBottomBorderButton(
                  variant: ThickButtonVariant.danger,
                  isFullWidth: true,
                  onPressed: _confirmLogout,
                  icon: Icon(AppIcons.prohibit, size: 18),
                  child: const Text('Keluar'),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppBrandIcon(
                        size: 26,
                        iconSize: 16,
                        borderWidth: 1,
                        shadowOffset: 1.5,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Serviso • Versi 1.0.0',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
