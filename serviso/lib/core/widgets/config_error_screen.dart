import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konfigurasi belum lengkap',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SUPABASE_URL atau SUPABASE_ANON_KEY belum diset, jadi '
                    'aplikasi belum bisa tersambung ke server. Jalankan '
                    'aplikasi dengan perintah berikut, lalu coba lagi:',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      'flutter run \\\n'
                      '  --dart-define=SUPABASE_URL=<url> \\\n'
                      '  --dart-define=SUPABASE_ANON_KEY=<anon-key>',
                      style: AppTypography.mono(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nilai ini dibaca saat aplikasi dimulai. Setelah mengubah '
                    '--dart-define, hentikan dan jalankan ulang aplikasi.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
