import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../features/auth/controllers/session_controller.dart';

class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    final profile = ref.watch(sessionProvider).valueOrNull;
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil',
            onPressed: () => context.go('/profil'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Halo, ${profile.fullName.isNotEmpty ? profile.fullName : profile.username}',
                style: textTheme.headlineSmall,
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Profil saya'),
              subtitle: const Text('Lihat dan ubah data akun'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profil'),
            ),
          ),
          if (isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.store_outlined),
                title: const Text('Kelola bengkel'),
                subtitle: const Text('Manajemen pengguna dan pengaturan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/admin'),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Pelanggan'),
              subtitle: const Text('Lihat dan kelola data pelanggan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/pelanggan'),
            ),
          ),
        ],
      ),
    );
  }
}
