import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';

class InventoriScreen extends StatelessWidget {
  const InventoriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Inventori', style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Stok part',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Stok Masuk'),
            ),
            child: const EmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'Stok masih kosong',
              message:
                  'Catat Stok Masuk pertama untuk mulai melacak part di '
                  'bengkel.',
            ),
          ),
        ],
      ),
    );
  }
}
