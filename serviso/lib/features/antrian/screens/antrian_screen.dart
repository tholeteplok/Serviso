import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';

class AntrianScreen extends StatelessWidget {
  const AntrianScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Antrian', style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Daftar WO',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Semua'),
            ),
            child: const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Antrian kosong',
              message:
                  'WO yang dibuat akan masuk ke sini. Tekan "Semua" untuk '
                  'melihat riwayat pekerjaan.',
            ),
          ),
        ],
      ),
    );
  }
}
