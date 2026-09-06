import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/theme/app_colors.dart';
import 'package:serviso/core/widgets/neo_filter_chip.dart';

void main() {
  group('NeoFilterChip', () {
    testWidgets('renders label and handles tap event', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NeoFilterChip(
                label: 'Suku Cadang',
                isSelected: isSelected,
                onTap: () => setState(() => isSelected = !isSelected),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Suku Cadang'), findsOneWidget);

      await tester.tap(find.text('Suku Cadang'));
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
    });

    testWidgets('renders optional icon and count badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeoFilterChip(
              label: 'Jasa',
              isSelected: true,
              icon: const Icon(Icons.build, size: 14),
              count: 5,
              activeColor: AppColors.pastelMint,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Jasa'), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
