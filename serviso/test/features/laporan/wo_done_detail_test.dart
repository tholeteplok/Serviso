import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/laporan/controllers/report_controllers.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';
import 'package:serviso/features/laporan/screens/details/wo_done_detail_screen.dart';

void main() {
  testWidgets('WoDoneDetailScreen renders summary, filter chips, and work order cards',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeReportRepo = FakeReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeReportRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WoDoneDetailScreen(),
        ),
      ),
    );

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // App Bar & period
    expect(find.text('Rincian WO Selesai'), findsOneWidget);
    expect(find.text('7 Hari'), findsWidgets);

    // Payment method filter chips
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Tunai'), findsWidgets);
    expect(find.text('QRIS'), findsWidgets);
    expect(find.text('Transfer'), findsWidgets);
    expect(find.text('Urutkan'), findsOneWidget);

    // Summary Card
    expect(find.text('Total WO'), findsOneWidget);
    expect(find.text('Total Pendapatan'), findsOneWidget);

    // Work order cards from FakeReportRepository
    expect(find.text('WO-2026-100'), findsOneWidget);
    expect(find.text('B 1000 XYZ'), findsOneWidget);
    expect(find.text('Pelanggan 1'), findsOneWidget);
    expect(find.textContaining('Honda Vario 150'), findsOneWidget);
  });

  testWidgets('WoDoneDetailScreen filter by Tunai updates list and summary',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeReportRepo = FakeReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeReportRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WoDoneDetailScreen(),
        ),
      ),
    );

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // Tap Tunai chip
    final tunaiChip = find.text('Tunai').first;
    await tester.tap(tunaiChip);
    await tester.pumpAndSettle();

    // Summary reflects Tunai filter
    expect(find.textContaining('dari Tunai'), findsOneWidget);
  });

  testWidgets('WoDoneDetailScreen search filters work order by plate or name',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeReportRepo = FakeReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeReportRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WoDoneDetailScreen(),
        ),
      ),
    );

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // Tap search icon
    final searchBtn = find.byTooltip('Cari WO Selesai');
    expect(searchBtn, findsOneWidget);
    await tester.tap(searchBtn);
    await tester.pumpAndSettle();

    // Enter query that does not match
    await tester.enterText(find.byType(TextField), 'ZZZZNOTEXIST');
    await tester.pumpAndSettle();

    expect(find.text('Tidak Ditemukan'), findsOneWidget);
  });
}
