import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Bengkel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Administrasi & Kontrol',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          _buildMenuCard(
            context,
            icon: Icons.manage_accounts_outlined,
            title: 'Kelola Pengguna',
            subtitle: 'Tambah akun kasir/admin, nonaktifkan, dan reset password',
            onTap: () => context.push(AppRoutes.adminUsers),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.history_edu_outlined,
            title: 'Audit Log Sistem',
            subtitle: 'Riwayat perubahan data, transaksi, dan aktivitas login/logout',
            onTap: () => context.push(AppRoutes.adminAuditLogs),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.store_outlined,
            title: 'Pengaturan Bengkel',
            subtitle: 'Ubah nama bengkel, alamat, dan nomor telepon cetakan struk',
            onTap: () => context.push(AppRoutes.pengaturan),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: AppColors.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: AppTypography.textTheme().titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: AppTypography.textTheme().bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        onTap: onTap,
      ),
    );
  }
}
