import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/controllers/session_controller.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadow.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../../features/auth/models/profile.dart';
import '../controllers/admin_controllers.dart';
import '../models/admin_models.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userListAsync = ref.watch(userListProvider);

    return Scaffold(
      appBar: const NeoAppBar(
        title: 'Kelola Pengguna',
      ),
      floatingActionButton: ThickBottomBorderButton(
        onPressed: () => _showAddUserDialog(context, ref),
        icon: Icon(AppIcons.addPerson, size: 18),
        child: const Text('Tambah User'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userListProvider),
        child: userListAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(userListProvider),
          ),
          data: (profiles) {
            if (profiles.isEmpty) {
              return const Center(child: Text('Belum ada pengguna'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = profiles[index];
                return _buildUserTile(context, ref, user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, WidgetRef ref, Profile user) {
    final isAdmin = user.role == UserRole.admin;

    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: user.isActive ? AppColors.pastelMint : AppColors.canvas,
                  borderRadius: AppRadius.button,
                  border: Border.all(color: AppColors.borderInk, width: 1.5),
                  boxShadow: AppShadow.l1,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isAdmin ? AppIcons.shieldCheck : AppIcons.user,
                  color: user.isActive ? AppColors.ink900 : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : user.username,
                      style: AppTypography.textTheme().titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: AppTypography.mono(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdmin ? AppColors.pastelYellow : AppColors.pastelBlue,
                  borderRadius: AppRadius.badge,
                  border: Border.all(color: AppColors.borderInk, width: 1),
                ),
                child: Text(
                  isAdmin ? 'Admin' : 'Kasir',
                  style: AppTypography.textTheme().bodySmall?.copyWith(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderHairline),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    user.isActive
                        ? AppIcons.checkCircle
                        : AppIcons.prohibit,
                    size: 16,
                    color: user.isActive ? AppColors.teal : AppColors.statusDanger,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.isActive ? 'Aktif' : 'Nonaktif',
                    style: AppTypography.textTheme().bodySmall?.copyWith(
                          color: user.isActive ? AppColors.teal : AppColors.statusDanger,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _confirmResetPassword(context, ref, user),
                    icon: Icon(AppIcons.lock, size: 16),
                    label: const Text('Reset Pass'),
                  ),
                  IconButton(
                    tooltip: user.isActive ? 'Nonaktifkan' : 'Aktifkan',
                    icon: Icon(
                      user.isActive
                          ? AppIcons.prohibit
                          : AppIcons.checkCircle,
                      color:
                          user.isActive ? AppColors.statusDanger : AppColors.teal,
                    ),
                    onPressed: () => _toggleUserActive(context, ref, user),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole selectedRole = UserRole.kasir;
    bool isLoading = false;

    showNeoBottomSheet(
      context: context,
      title: 'Tambah Pengguna Baru',
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoTextField(
                  key: const Key('input_username'),
                  controller: usernameCtrl,
                  labelText: 'Username *',
                  hintText: 'mis. kasir2',
                  helperText: 'Huruf kecil, angka, titik, strip tanpa spasi',
                  prefixIcon: AppIcons.user,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('input_fullname'),
                  controller: nameCtrl,
                  labelText: 'Nama Lengkap *',
                  hintText: 'mis. Andi Saputra',
                  prefixIcon: AppIcons.user,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('input_password'),
                  controller: passwordCtrl,
                  labelText: 'Password Awal *',
                  hintText: 'min. 6 karakter',
                  prefixIcon: AppIcons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('input_email'),
                  controller: emailCtrl,
                  labelText: 'Email Pemulihan (Opsional)',
                  hintText: 'andi@example.com',
                  prefixIcon: AppIcons.notepad,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Peran (Role)',
                    prefixIcon: Icon(AppIcons.shieldCheck, color: AppColors.ink900),
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.button,
                      borderSide: BorderSide(color: AppColors.borderInk, width: 1.5),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.button,
                      borderSide: BorderSide(color: AppColors.borderInk, width: 1.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.button,
                      borderSide: BorderSide(color: AppColors.borderInk, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.kasir,
                      child: Text('Kasir'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin / Pemilik'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 20),
                ThickBottomBorderButton(
                  isFullWidth: true,
                  onPressed: isLoading
                      ? null
                      : () async {
                          final rawUsername = usernameCtrl.text.trim().toLowerCase();
                          final name = nameCtrl.text.trim();
                          final password = passwordCtrl.text.trim();
                          final email = emailCtrl.text.trim();

                          if (rawUsername.isEmpty || name.isEmpty || password.isEmpty) {
                            _showErrorDialog(
                              context,
                              title: 'Data Belum Lengkap',
                              message:
                                  'Username, Nama Lengkap, dan Password awal wajib diisi untuk membuat akun pengguna.',
                              buttonLabel: 'Perbaiki Data',
                            );
                            return;
                          }

                          final usernameRegex = RegExp(r'^[a-z0-9_.-]{3,30}$');
                          if (!usernameRegex.hasMatch(rawUsername)) {
                            _showErrorDialog(
                              context,
                              title: 'Format Username Tidak Valid',
                              message:
                                  'Username harus 3-30 karakter (hanya boleh huruf kecil, angka, titik, strip, atau garis bawah tanpa spasi).',
                              buttonLabel: 'Perbaiki Data',
                            );
                            return;
                          }

                          if (password.length < 6) {
                            _showErrorDialog(
                              context,
                              title: 'Password Terlalu Pendek',
                              message: 'Password awal minimal 6 karakter demi keamanan akun pengguna.',
                              buttonLabel: 'Perbaiki Data',
                            );
                            return;
                          }

                          if (email.isNotEmpty) {
                            final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                            if (!emailRegex.hasMatch(email)) {
                              _showErrorDialog(
                                context,
                                title: 'Format Email Tidak Valid',
                                message:
                                    'Format email pemulihan tidak valid (contoh: user@gmail.com). Kosongkan jika tidak diperlukan.',
                                buttonLabel: 'Perbaiki Data',
                              );
                              return;
                            }
                          }

                          setState(() => isLoading = true);
                          try {
                            final repo = ref.read(adminRepositoryProvider);
                            await repo.createUser(
                              CreateUserPayload(
                                username: rawUsername,
                                fullName: name,
                                password: password,
                                email: email.isEmpty ? null : email,
                                role: selectedRole,
                              ),
                            );
                            ref.invalidate(userListProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pengguna @$rawUsername berhasil dibuat.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (context.mounted) {
                              _showErrorDialog(
                                context,
                                title: 'Gagal Menambahkan Pengguna',
                                message: e.toString(),
                                buttonLabel: 'Perbaiki Data',
                                ref: ref,
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan Pengguna'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleUserActive(BuildContext context, WidgetRef ref, Profile user) async {
    final actionName = user.isActive ? 'menonaktifkan' : 'mengaktifkan';
    final confirm = await showNeoConfirmDialog(
      context: context,
      title: 'Konfirmasi ${user.isActive ? 'Nonaktifkan' : 'Aktifkan'}',
      message:
          'Apakah Anda yakin ingin $actionName pengguna @${user.username}?',
      confirmLabel: user.isActive ? 'Nonaktifkan' : 'Aktifkan',
      isDanger: user.isActive,
    );

    if (confirm == true) {
      try {
        final repo = ref.read(adminRepositoryProvider);
        await repo.toggleUserActive(user.id, !user.isActive);
        ref.invalidate(userListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pengguna @${user.username} berhasil di-${user.isActive ? 'nonaktifkan' : 'aktifkan'}.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorDialog(
            context,
            title: 'Gagal Mengubah Status',
            message: e.toString(),
            ref: ref,
          );
        }
      }
    }
  }

  void _confirmResetPassword(
      BuildContext context, WidgetRef ref, Profile user) async {
    final confirm = await showNeoConfirmDialog(
      context: context,
      title: 'Reset Password',
      message: 'Kirimkan instruksi reset password untuk @${user.username}?',
      confirmLabel: 'Kirim Email',
      isDanger: false,
    );

    if (confirm == true) {
      try {
        final repo = ref.read(adminRepositoryProvider);
        await repo.sendResetPassword(user.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Instruksi reset password untuk @${user.username} telah dikirim.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorDialog(
            context,
            title: 'Gagal Reset Password',
            message: e.toString(),
            ref: ref,
          );
        }
      }
    }
  }

  void _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Tutup',
    WidgetRef? ref,
  }) {
    final lowerMessage = message.toLowerCase();
    final isSessionExpired = lowerMessage.contains('sesi tidak valid') ||
        lowerMessage.contains('telah berakhir') ||
        lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('401');

    final effectiveTitle = isSessionExpired ? 'Sesi Kedaluwarsa' : title;
    final effectiveButtonLabel =
        isSessionExpired ? 'Login Ulang' : buttonLabel;

    showNeoDialog(
      context: context,
      builder: (dialogCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.pastelPink,
              borderRadius: AppRadius.button,
              border: Border.all(color: AppColors.borderInk, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(AppIcons.warning, color: AppColors.ink900, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            effectiveTitle,
            style: AppTypography.chakra(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTypography.textTheme().bodyMedium?.copyWith(
                  color: AppColors.ink900,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ThickBottomBorderButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (isSessionExpired && ref != null) {
                  ref.read(sessionProvider.notifier).logout();
                }
              },
              child: Text(effectiveButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
