import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/direct_sales/data/hold_transaction_service.dart';
import 'package:serviso/features/direct_sales/models/direct_sale.dart';
import 'package:serviso/features/direct_sales/screens/retail_sales_screen.dart';
import 'package:serviso/features/laporan/controllers/report_controllers.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';
import 'package:serviso/features/workorders/models/payment.dart';
import 'package:serviso/features/workorders/models/work_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RetailSalesScreen Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('RetailSalesScreen displays empty state when no drafts', (tester) async {
      final fakeReportRepo = FakeReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
            holdDraftsProvider.overrideWith((ref) => HoldTransactionNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RetailSalesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Penjualan'), findsOneWidget);
      expect(find.text('Tertunda'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Tidak Ada Transaksi Tertunda'), findsOneWidget);
    });

    testWidgets('RetailSalesScreen displays draft cards with resume and delete', (tester) async {
      final fakeReportRepo = FakeReportRepository();
      final notifier = HoldTransactionNotifier();

      final draft = HoldSaleDraft(
        id: 'draft-999',
        customerName: 'Ahmad Dahlan',
        createdAt: DateTime.now(),
        items: const [
          DirectSaleItemInput(
            kind: WoItemKind.part,
            description: 'Kampas Rem Depan',
            qty: 2,
            unitPrice: 45000,
          ),
        ],
        payMethod: PaymentMethod.cash,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
            holdDraftsProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RetailSalesScreen(),
          ),
        ),
      );

      await notifier.saveDraft(draft);
      await tester.pumpAndSettle();

      expect(find.text('Tertunda (1)'), findsOneWidget);
      expect(find.text('Ahmad Dahlan'), findsOneWidget);
      expect(find.text('Kampas Rem Depan'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsOneWidget);
    });

    testWidgets('RetailSalesScreen switches to Selesai tab and shows sales', (tester) async {
      final fakeReportRepo = FakeReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
            holdDraftsProvider.overrideWith((ref) => HoldTransactionNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RetailSalesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Selesai' segment
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('7 Hari'), findsOneWidget);
      expect(find.text('30 Hari'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('TOTAL TRANSAKSI'), findsOneWidget);
      expect(find.text('TOTAL OMSET'), findsOneWidget);
    });
  });
}
