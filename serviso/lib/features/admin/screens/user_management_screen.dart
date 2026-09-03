import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  prefixIcon: AppIcons.user,
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
                          final username = usernameCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          if (username.isEmpty || name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Username dan Nama Lengkap wajib diisi.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);
                          try {
                            final repo = ref.read(adminRepositoryProvider);
                            await repo.createUser(
                              CreateUserPayload(
                                username: username,
                                fullName: name,
                                email: emailCtrl.text.trim().isEmpty
                                    ? null
                                    : emailCtrl.text.trim(),
                                role: selectedRole,
                              ),
                            );
                            ref.invalidate(userListProvider);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Undangan pengguna $username berhasil dibuat.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.action,
                                ),
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
                      : const Text('Simpan & Undang'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.action,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.action,
            ),
          );
        }
      }
    }
  }
}
