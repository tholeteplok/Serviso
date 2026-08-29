import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../../../features/auth/models/profile.dart';
import '../controllers/admin_controllers.dart';
import '../models/admin_models.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userListAsync = ref.watch(userListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, ref),
        icon: Icon(AppIcons.addPerson),
        label: const Text('Tambah User'),
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderHairline, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: user.isActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.line,
                  child: Icon(
                    isAdmin
                        ? AppIcons.shieldCheck
                        : AppIcons.user,
                    color: user.isActive ? AppColors.primary : AppColors.inkMuted,
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
                              color: AppColors.ink,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: AppTypography.mono(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAdmin
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.teal.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Kasir',
                    style: AppTypography.textTheme().bodySmall?.copyWith(
                          color: isAdmin ? AppColors.primary : AppColors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.line),
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
                      color: user.isActive ? AppColors.teal : AppColors.action,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isActive ? 'Aktif' : 'Nonaktif',
                      style: AppTypography.textTheme().bodySmall?.copyWith(
                            color:
                                user.isActive ? AppColors.teal : AppColors.action,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmResetPassword(context, ref, user),
                      icon: const Icon(Icons.lock_reset, size: 18),
                      label: const Text('Reset Pass'),
                    ),
                    IconButton(
                      tooltip: user.isActive ? 'Nonaktifkan' : 'Aktifkan',
                      icon: Icon(
                        user.isActive
                            ? AppIcons.prohibit
                            : AppIcons.checkCircle,
                        color:
                            user.isActive ? AppColors.action : AppColors.teal,
                      ),
                      onPressed: () => _toggleUserActive(context, ref, user),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole selectedRole = UserRole.kasir;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Pengguna Baru',
                    style: AppTypography.textTheme().titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('input_username'),
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      hintText: 'mis. kasir2',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input_fullname'),
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap *',
                      hintText: 'mis. Andi Saputra',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input_email'),
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email Pemulihan (Opsional)',
                      hintText: 'andi@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Peran (Role)'),
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan & Undang'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleUserActive(BuildContext context, WidgetRef ref, Profile user) async {
    final actionName = user.isActive ? 'menonaktifkan' : 'mengaktifkan';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi ${user.isActive ? 'Nonaktifkan' : 'Aktifkan'}'),
        content: Text(
          'Apakah Anda yakin ingin $actionName pengguna @${user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Kirimkan instruksi reset password untuk @${user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim Email'),
          ),
        ],
      ),
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
