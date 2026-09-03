import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadow.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_card.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();

    return Scaffold(
      appBar: const NeoAppBar(
        title: 'Kelola Bengkel',
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
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _buildMenuCard(
            context,
            icon: AppIcons.usersThree,
            iconBg: AppColors.pastelBlue,
            title: 'Kelola Pengguna',
            subtitle: 'Tambah akun kasir/admin, nonaktifkan, dan reset password',
            onTap: () => context.push(AppRoutes.adminUsers),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: AppIcons.clipboardList,
            iconBg: AppColors.pastelYellow,
            title: 'Audit Log Sistem',
            subtitle: 'Riwayat perubahan data, transaksi, dan aktivitas login/logout',
            onTap: () => context.push(AppRoutes.adminAuditLogs),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: AppIcons.storefront,
            iconBg: AppColors.pastelMint,
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
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.button,
              border: Border.all(color: AppColors.borderInk, width: 1.5),
              boxShadow: AppShadow.l1,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.ink900, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme().titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.textTheme().bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(AppIcons.caretRight, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}
