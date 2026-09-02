import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/widgets/chart_empty_box.dart';
import 'package:serviso/core/widgets/horizontal_bar_list.dart';
import 'package:serviso/core/widgets/neo_bar_chart.dart';
import 'package:serviso/core/widgets/neo_line_chart.dart';

void main() {
  group('ChartEmptyBox Widget Tests', () {
    testWidgets('renders title and message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartEmptyBox(
              title: 'Tidak ada data',
              message: 'Silakan pilih tanggal lain',
            ),
          ),
        ),
      );

      expect(find.text('Tidak ada data'), findsOneWidget);
      expect(find.text('Silakan pilih tanggal lain'), findsOneWidget);
    });
  });

  group('NeoBarChart Widget Tests', () {
    testWidgets('renders empty box when items are empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeoBarChart(items: []),
          ),
        ),
      );

      expect(find.byType(ChartEmptyBox), findsOneWidget);
    });

    testWidgets('renders bars when data present', (tester) async {
      final items = [
        const NeoBarChartItem(label: '1/6', value: 100000),
        const NeoBarChartItem(label: '2/6', value: 300000), // Peak
        const NeoBarChartItem(label: '3/6', value: 150000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: NeoBarChart(
                items: items,
                valueFormatter: (v) => 'Rp $v',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NeoBarChart), findsOneWidget);
      expect(find.textContaining('2/6'), findsWidgets);
    });
  });

  group('NeoLineChart Widget Tests', () {
    testWidgets('renders empty box when points are empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeoLineChart(points: []),
          ),
        ),
      );

      expect(find.byType(ChartEmptyBox), findsOneWidget);
    });

    testWidgets('renders points when data present', (tester) async {
      final points = [
        const NeoLineChartPoint(x: 0, y: 100000, label: 'Sen'),
        const NeoLineChartPoint(x: 1, y: 500000, label: 'Sel'), // Peak
        const NeoLineChartPoint(x: 2, y: 200000, label: 'Rab'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: NeoLineChart(
                points: points,
                valueFormatter: (v) => 'Rp $v',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NeoLineChart), findsOneWidget);
      expect(find.textContaining('Sel'), findsWidgets);
    });
  });

  group('HorizontalBarList Widget Tests', () {
    testWidgets('renders ranked items with quantity badges and subtitles', (tester) async {
      final items = [
        const HorizontalBarItem(
          title: 'Oli Motul 1L',
          value: 47,
          valueLabel: '47×',
          subtitle: 'Rp 89.000 • 47 pcs terjual',
        ),
        const HorizontalBarItem(
          title: 'Kampas Rem Beat',
          value: 32,
          valueLabel: '32×',
          subtitle: 'Rp 45.000 • 32 pcs terjual',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalBarList(items: items),
          ),
        ),
      );

      expect(find.text('Oli Motul 1L'), findsOneWidget);
      expect(find.text('47×'), findsOneWidget);
      expect(find.text('Rp 89.000 • 47 pcs terjual'), findsOneWidget);
      expect(find.text('Kampas Rem Beat'), findsOneWidget);
      expect(find.text('32×'), findsOneWidget);
    });
  });
}