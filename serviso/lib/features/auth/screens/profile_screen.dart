import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/section_card.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.action),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final profile = ref.watch(sessionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.tintPrimary,
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : profile.username[0].toUpperCase(),
                      style: AppTypography.chakra(
                        fontSize: 28,
                        color: AppColors.primary,
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tintPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      userRoleLabel[profile.role] ?? 'Kasir',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Data akun',
                  trailing: _editing
                      ? null
                      : TextButton(
                          onPressed: () => setState(() => _editing = true),
                          child: const Text('Ubah'),
                        ),
                  child: Column(
                    children: [
                      _FieldRow(
                        label: 'Nama lengkap',
                        child: _editing
                            ? TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Nama lengkap',
                                ),
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
                            ? TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  hintText: 'Nomor telepon',
                                ),
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
                                  ?.copyWith(color: AppColors.action),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.surface,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.action,
                      side: const BorderSide(color: AppColors.action),
                    ),
                    onPressed: _confirmLogout,
                    child: const Text('Keluar'),
                  ),
                ),
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
