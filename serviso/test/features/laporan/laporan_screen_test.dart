import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/laporan/controllers/report_controllers.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';
import 'package:serviso/features/laporan/screens/laporan_screen.dart';

void main() {
  testWidgets('LaporanScreen renders period chips, metrics, and top parts',
      (tester) async {
    final fakeReportRepo = FakeReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeReportRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LaporanScreen(),
        ),
      ),
    );

    // Pump multiple times to settle all async FutureProviders
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.text('7 Hari'), findsOneWidget);
    expect(find.text('30 Hari'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);

    expect(find.text('Total Omset'), findsOneWidget);
    expect(find.text('WO Selesai'), findsOneWidget);
    expect(find.text('Grafik Pendapatan Harian'), findsOneWidget);
    expect(
      find.text('Suku Cadang Terlaris Bulan Ini', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Oli Mesin 1L', skipOffstage: false),
      findsOneWidget,
    );
  });
}
