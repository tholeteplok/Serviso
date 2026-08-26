import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat bekerja,',
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.inkMuted),
                    ),
                    Text('Serviso', style: textTheme.headlineSmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Akun',
                onPressed: () {},
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _StatTile(label: 'WO Aktif', value: '0'),
              const SizedBox(width: 10),
              const _StatTile(label: 'Stok Kritis', value: '0'),
              const SizedBox(width: 10),
              _StatTile(label: 'Omzet Hari Ini', value: rupiah(0)),
            ],
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Antrian hari ini',
            child: EmptyState(
              icon: Icons.schedule_rounded,
              title: 'Belum ada antrean',
              message:
                  'WO yang masuk hari ini akan tampil di sini. Buat WO baru '
                  'untuk mulai melayani pelanggan.',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.chakra(
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme()
                  .labelSmall
                  ?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
