import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Laporan', style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Bulan ini',
            child: EmptyState(
              icon: Icons.insights_rounded,
              title: 'Belum ada data laporan',
              message:
                  'Laporan pendapatan dan pekerjaan terisi otomatis setelah '
                  'ada WO yang selesai.',
            ),
          ),
        ],
      ),
    );
  }
}
