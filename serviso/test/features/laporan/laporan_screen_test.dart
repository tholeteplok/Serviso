import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/auth/models/profile.dart';
import 'package:serviso/features/laporan/controllers/report_controllers.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';
import 'package:serviso/features/laporan/screens/details/customer_report_screen.dart';
import 'package:serviso/features/laporan/screens/laporan_screen.dart';

void main() {
  testWidgets('LaporanScreen renders period chips, metrics, Pelanggan card for staff',
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
          isAdminProvider.overrideWith((ref) => false),
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

    expect(find.text('7 Hari'), findsOneWidget);
    expect(find.text('30 Hari'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);

    expect(find.text('Total Omset'), findsOneWidget);
    expect(find.text('Pelanggan & CRM'), findsOneWidget);
    expect(find.text('WO Selesai'), findsOneWidget);
    expect(find.text('Grafik Pendapatan Harian'), findsOneWidget);
    expect(
      find.text('Suku Cadang Terlaris Bulan Ini', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('LaporanScreen renders combined Laba & Omset and Pelanggan & CRM for admin',
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

    expect(find.text('Laba & Omset'), findsOneWidget);
    expect(find.text('Pelanggan & CRM'), findsOneWidget);
    expect(find.text('Penjualan Langsung'), findsOneWidget);
    expect(find.text('Hutang Distributor'), findsOneWidget);
  });

  testWidgets('LaporanScreen hides WO Selesai metric when shopBusinessType is barang',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeReportRepo = FakeReportRepository();
    const mockRetailProfile = Profile(
      id: 'u-retail',
      username: 'retail_owner',
      fullName: 'Toko Retail Sukses',
      role: UserRole.admin,
      shopBusinessType: 'barang',
      isActive: true,
    );
    final fakeAuthRepo = FakeAuthRepository()..profileToReturn = mockRetailProfile;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeReportRepo),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
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

    expect(find.text('Laba & Omset'), findsOneWidget);
    expect(find.text('Pelanggan & CRM'), findsOneWidget);
    expect(find.text('Penjualan Langsung'), findsOneWidget);
    expect(find.text('Hutang Distributor'), findsOneWidget);
    expect(find.text('Part Terjual'), findsOneWidget);
    expect(find.text('WO Selesai'), findsNothing);
  });

  testWidgets('CustomerReportScreen renders metrics summary and customer cards',
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
          home: const CustomerReportScreen(),
        ),
      ),
    );

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.text('Pelanggan & CRM'), findsOneWidget);
    expect(find.text('Total Pelanggan'), findsOneWidget);
    expect(find.text('Aktif Bulan Ini'), findsOneWidget);
    expect(find.text('Total Omset Pelanggan'), findsOneWidget);
    expect(find.text('Rata-rata LTV'), findsOneWidget);

    // Customer items from fake repo
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Agus Pratama'), findsOneWidget);
  });
}
