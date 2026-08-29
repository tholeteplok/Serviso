import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/widgets/neo_search_bar.dart';
import 'package:serviso/core/widgets/neo_segment_control.dart';
import 'package:serviso/core/widgets/neo_stepper.dart';
import 'package:serviso/core/widgets/neo_switch.dart';

void main() {
  group('NeoSwitch', () {
    testWidgets('toggles value when tapped', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NeoSwitch(
                value: value,
                onChanged: (val) => setState(() => value = val),
              ),
            ),
          ),
        ),
      );

      expect(value, isFalse);
      await tester.tap(find.byType(NeoSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });
  });

  group('NeoSegmentControl', () {
    testWidgets('switches selected value when item tapped', (tester) async {
      String selected = 'hari';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NeoSegmentControl<String>(
                selectedValue: selected,
                onValueChanged: (val) => setState(() => selected = val),
                items: const [
                  NeoSegmentItem(value: 'hari', label: '7 Hari'),
                  NeoSegmentItem(value: 'bulan', label: 'Bulan Ini'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('7 Hari'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);

      await tester.tap(find.text('Bulan Ini'));
      await tester.pumpAndSettle();
      expect(selected, 'bulan');
    });
  });

  group('NeoSearchBar', () {
    testWidgets('invokes onChanged and scan callback', (tester) async {
      String text = '';
      bool scanned = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeoSearchBar(
              controller: controller,
              onChanged: (v) => text = v,
              onScanTap: () => scanned = true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'kampas');
      expect(text, 'kampas');

      await tester.tap(find.byTooltip('Scan Barcode'));
      expect(scanned, isTrue);
    });
  });

  group('NeoStepper', () {
    testWidgets('increments and decrements value correctly', (tester) async {
      num count = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => NeoStepper(
                value: count,
                min: 1,
                max: 10,
                onChanged: (val) => setState(() => count = val),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);

      // Tap increment [+]
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(count, 3);

      // Tap decrement [-]
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(count, 2);
    });
  });
}
