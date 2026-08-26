import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/widgets/plate_chip.dart';

void main() {
  testWidgets('menampilkan plat dalam uppercase hasil normalisasi',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PlateChip(plateText: ' b 1234 xyz ')),
        ),
      ),
    );

    expect(find.text('B 1234 XYZ'), findsOneWidget);
  });
}
