import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/core/widgets/neo_segment_control.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/laporan/controllers/report_controllers.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';
import 'package:serviso/features/laporan/models/report_models.dart';
import 'package:serviso/features/laporan/screens/details/debt_detail_screen.dart';
import 'package:serviso/features/laporan/screens/details/debt_history_sheet.dart';
import 'package:serviso/features/laporan/screens/details/debt_payment_sheet.dart';

void main() {
  group('DistributorDebtItem Model Calculations', () {
    test('computes remaining, isSettled, and paymentProgress accurately', () {
      final item = DistributorDebtItem(
        movementId: 'm1',
        partId: 'p1',
        partName: 'Oli Mesin',
        distributor: 'PT Lubricants',
        qty: 10,
        purchasePrice: 100000,
        totalDebt: 1000000,
        totalPaid: 400000,
        createdAt: DateTime.now(),
        debtStatus: 'belum_lunas',
      );

      expect(item.totalDebt, 1000000);
      expect(item.totalPaid, 400000);
      expect(item.remaining, 600000);
      expect(item.isSettled, false);
      expect(item.paymentProgress, 0.4);

      final settledItem = DistributorDebtItem(
        movementId: 'm2',
        partId: 'p1',
        partName: 'Oli Mesin',
        distributor: 'PT Lubricants',
        qty: 10,
        purchasePrice: 100000,
        totalDebt: 1000000,
        totalPaid: 1000000,
        createdAt: DateTime.now(),
        debtStatus: 'lunas',
      );

      expect(settledItem.remaining, 0);
      expect(settledItem.isSettled, true);
      expect(settledItem.paymentProgress, 1.0);
    });
  });

  group('FakeReportRepository Partial Debt Payments', () {
    test('records partial payments and updates debt status when settled', () async {
      final repo = FakeReportRepository();

      // Initial debt
      final initialDebts = await repo.fetchDistributorDebts(status: 'belum_lunas');
      expect(initialDebts.length, 1);
      final debt = initialDebts.first;
      expect(debt.totalDebt, 750000);
      expect(debt.totalPaid, 0);
      expect(debt.remaining, 750000);

      // 1. Partial payment Rp 300.000 via Transfer
      final res1 = await repo.payDebt(
        movementId: debt.movementId,
        amount: 300000,
        payMethod: 'Transfer',
        note: 'Cicilan 1 via BCA',
      );
      expect(res1['total_paid'], 300000);
      expect(res1['remaining'], 450000);
      expect(res1['is_settled'], false);

      // Verify updated debt list
      final debtsAfter1 = await repo.fetchDistributorDebts(status: 'belum_lunas');
      expect(debtsAfter1.first.totalPaid, 300000);
      expect(debtsAfter1.first.remaining, 450000);
      expect(debtsAfter1.first.isSettled, false);

      // Check payment records
      final history1 = await repo.fetchDebtPayments(debt.movementId);
      expect(history1.length, 1);
      expect(history1.first.amount, 300000);
      expect(history1.first.payMethod, 'Transfer');
      expect(history1.first.note, 'Cicilan 1 via BCA');

      // 2. Second partial payment Rp 450.000 via Tunai (settles the debt)
      final res2 = await repo.payDebt(
        movementId: debt.movementId,
        amount: 450000,
        payMethod: 'Tunai',
        note: 'Pelunasan sisa',
      );
      expect(res2['total_paid'], 750000);
      expect(res2['remaining'], 0);
      expect(res2['is_settled'], true);

      // Verify debt is now in lunas list
      final unpaidDebts = await repo.fetchDistributorDebts(status: 'belum_lunas');
      expect(unpaidDebts.isEmpty, true);

      final paidDebts = await repo.fetchDistributorDebts(status: 'lunas');
      expect(paidDebts.length, 1);
      expect(paidDebts.first.isSettled, true);

      // Check complete history
      final fullHistory = await repo.fetchDebtPayments(debt.movementId);
      expect(fullHistory.length, 2);
      expect(fullHistory[0].amount, 300000);
      expect(fullHistory[1].amount, 450000);
    });
  });

  group('DebtDetailScreen & Bottom Sheets UI', () {
    testWidgets('DebtDetailScreen renders summary with Total, Terbayar, Sisa (Opsi C)',
        (tester) async {
      final fakeReportRepo = FakeReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const DebtDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rincian Hutang'), findsOneWidget);
      expect(find.text('Total Hutang'), findsWidgets);
      expect(find.text('Terbayar'), findsWidgets);
      expect(find.text('Sisa'), findsOneWidget);
      expect(find.text('Bayar'), findsOneWidget);
    });

    testWidgets('DebtPaymentSheet validates and records payment',
        (tester) async {
      final fakeReportRepo = FakeReportRepository();
      final debts = await fakeReportRepo.fetchDistributorDebts();
      final debt = debts.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
          ],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: DebtPaymentSheet(debt: debt, parentRef: ref),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bayar Hutang'), findsOneWidget);
      expect(find.byKey(const Key('debt_amount')), findsOneWidget);
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('QRIS'), findsOneWidget);

      // Enter partial amount
      await tester.enterText(find.byKey(const Key('debt_amount')), '250000');
      await tester.enterText(find.byKey(const Key('debt_note')), 'Cicilan via QRIS');

      // Select QRIS
      await tester.tap(find.text('QRIS'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Bayar'));
      await tester.pumpAndSettle();

      final history = await fakeReportRepo.fetchDebtPayments(debt.movementId);
      expect(history.length, 1);
      expect(history.first.amount, 250000);
      expect(history.first.payMethod, 'QRIS');
      expect(history.first.note, 'Cicilan via QRIS');
    });

    testWidgets('DebtHistorySheet renders payment records',
        (tester) async {
      final fakeReportRepo = FakeReportRepository();
      final debts = await fakeReportRepo.fetchDistributorDebts();
      final debt = debts.first;

      // Seed a payment
      await fakeReportRepo.payDebt(
        movementId: debt.movementId,
        amount: 250000,
        payMethod: 'Transfer',
        note: 'Nota Cicilan #1',
      );

      final updatedDebts = await fakeReportRepo.fetchDistributorDebts();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: DebtHistorySheet(debt: updatedDebts.first),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Riwayat Pembayaran'), findsOneWidget);
      expect(find.text('Metode: Transfer'), findsOneWidget);
      expect(find.text('Nota Cicilan #1'), findsOneWidget);
    });

    testWidgets('DebtDetailScreen displays debts from multiple distributors and switches tabs',
        (tester) async {
      final fakeReportRepo = FakeReportRepository();
      fakeReportRepo.mockDistributorDebts = [
        DistributorDebtItem(
          movementId: 'm-1',
          partId: 'p-1',
          partName: 'Busi Champion',
          distributor: 'Panca Mandiri',
          qty: 10,
          purchasePrice: 25000,
          totalDebt: 250000,
          totalPaid: 100000,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          debtStatus: 'belum_lunas',
        ),
        DistributorDebtItem(
          movementId: 'm-2',
          partId: 'p-2',
          partName: 'Oli MPX 0.8L',
          distributor: 'cv. Tirta Nugraha',
          qty: 20,
          purchasePrice: 5000,
          totalDebt: 100000,
          totalPaid: 0,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          debtStatus: 'belum_lunas',
        ),
        DistributorDebtItem(
          movementId: 'm-3',
          partId: 'p-3',
          partName: 'Kampas Ganda',
          distributor: 'Tirta Nugraha',
          qty: 8,
          purchasePrice: 0, // 0 purchase price fallback
          totalDebt: 0,
          totalPaid: 0,
          createdAt: DateTime.now(),
          debtStatus: 'belum_lunas',
        ),
        DistributorDebtItem(
          movementId: 'm-4',
          partId: 'p-4',
          partName: 'Filter Oli',
          distributor: 'PT Astra Otoparts',
          qty: 5,
          purchasePrice: 30000,
          totalDebt: 150000,
          totalPaid: 150000,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          debtStatus: 'lunas',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            reportRepositoryProvider.overrideWithValue(fakeReportRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const DebtDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On Belum Lunas tab, all 3 unpaid debts from different distributors must appear
      expect(find.text('Panca Mandiri'), findsOneWidget);
      expect(find.text('cv. Tirta Nugraha'), findsOneWidget);
      expect(find.text('Tirta Nugraha'), findsOneWidget);
      expect(find.text('PT Astra Otoparts'), findsNothing);

      // Switch to Lunas tab
      await tester.tap(
        find.descendant(
          of: find.byType(NeoSegmentControl<DebtFilter>),
          matching: find.text('Lunas'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PT Astra Otoparts'), findsOneWidget);
      expect(find.text('Panca Mandiri'), findsNothing);
      expect(find.text('cv. Tirta Nugraha'), findsNothing);
      expect(find.text('Tirta Nugraha'), findsNothing);
    });
  });
}
