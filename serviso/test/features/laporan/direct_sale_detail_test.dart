import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/laporan/controllers/report_controllers.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';
import 'package:serviso/features/laporan/models/report_models.dart';
import 'package:serviso/features/laporan/pdf/laporan_export.dart';
import 'package:serviso/features/laporan/screens/details/direct_sale_detail_screen.dart';
import 'package:serviso/features/laporan/screens/details/profit_detail_screen.dart';
import 'package:serviso/features/laporan/screens/laporan_screen.dart';

void main() {
  group('DirectSaleDetailScreen & ProfitDetailScreen Tests', () {
    testWidgets('LaporanScreen displays Penjualan Langsung card',
        (tester) async {
      final fakeReportRepo = FakeReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
            isAdminProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LaporanScreen(),
          ),
        ),
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('Penjualan Langsung'), findsOneWidget);
    });

    testWidgets('ProfitDetailScreen renders Total HPP card with chevron',
        (tester) async {
      final fakeReportRepo = FakeReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
            isAdminProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfitDetailScreen(),
          ),
        ),
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('Total HPP'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('DirectSaleDetailScreen renders summary cards and transaction cards',
        (tester) async {
      final fakeReportRepo = FakeReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
            isAdminProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const DirectSaleDetailScreen(),
          ),
        ),
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(find.text('Total Penjualan'), findsOneWidget);
      expect(find.text('Total Transaksi'), findsOneWidget);
      expect(find.text('Item Terjual'), findsOneWidget);
      expect(find.textContaining('DS-260902-'), findsWidgets);
    });

    test('buildDirectSaleReportPdf and buildDirectSaleReportCsv produce non-empty outputs',
        () async {
      final rows = [
        DirectSaleReportRow(
          id: 'ds-1',
          saleNumber: 'DS-260902-001',
          paidAt: DateTime.now(),
          paidAmount: 17500,
          payMethod: 'tunai',
          customerName: 'Umum',
          itemCount: 1,
          items: const [
            DirectSaleItemReportRow(
              kind: 'part',
              description: 'Kuaci Rebo 10g',
              qty: 7,
              unitPrice: 2500,
              partName: 'Kuaci Rebo 10g',
            ),
          ],
        ),
      ];

      final pdfBytes = await buildDirectSaleReportPdf(
        rows: rows,
        periodLabel: '7 Hari',
        exportedAt: DateTime.now(),
      );
      expect(pdfBytes.isNotEmpty, isTrue);

      final csv = buildDirectSaleReportCsv(rows);
      expect(csv, contains('DS-260902-001'));
      expect(csv, contains('17500'));
    });
  });
}
