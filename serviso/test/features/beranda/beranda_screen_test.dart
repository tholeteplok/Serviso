import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/auth/models/profile.dart';
import 'package:serviso/features/beranda/screens/beranda_screen.dart';
import 'package:serviso/features/laporan/controllers/report_controllers.dart';
import 'package:serviso/features/laporan/data/report_repository.dart';

void main() {
  testWidgets('BerandaScreen rendering stat cards & quick actions', (tester) async {
    final fakeReportRepo = FakeReportRepository();
    const mockProfile = Profile(
      id: 'u1',
      username: 'admin',
      fullName: 'Pemilik Bengkel',
      role: UserRole.admin,
      isActive: true,
    );
    final fakeAuthRepo = FakeAuthRepository()..profileToReturn = mockProfile;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeReportRepo),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BerandaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Halo, Pemilik Bengkel'), findsOneWidget);
    expect(find.text('Pendapatan Hari Ini'), findsOneWidget);
    expect(find.text('Tunai'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('WO Aktif'), findsOneWidget);
    expect(find.text('Stok Menipis'), findsOneWidget);
    expect(find.text('Tren Pendapatan 7 Hari'), findsOneWidget);
    expect(find.text('Aksi Cepat'), findsOneWidget);
    expect(find.text('WO Baru'), findsOneWidget);
    expect(find.text('Jual Langsung'), findsOneWidget);
    expect(find.text('Inventori'), findsOneWidget);
  });

  testWidgets('BerandaScreen hides WO and adapts to Retail mode (shopBusinessType == barang)', (tester) async {
    final fakeReportRepo = FakeReportRepository();
    const mockRetailProfile = Profile(
      id: 'u2',
      username: 'owner_retail',
      fullName: 'Toko Sparepart Jaya',
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
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BerandaScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Halo, Toko Sparepart Jaya'), findsOneWidget);
    expect(find.text('Pendapatan Hari Ini'), findsOneWidget);
    // Stat tile should be Penjualan Hari Ini, NOT WO Aktif
    expect(find.text('Penjualan Hari Ini'), findsOneWidget);
    expect(find.text('WO Aktif'), findsNothing);
    expect(find.text('Stok Menipis'), findsOneWidget);

    // Quick actions should have Kasir & Tambah Stok, NOT WO Baru
    expect(find.text('Aksi Cepat'), findsOneWidget);
    expect(find.text('Kasir'), findsOneWidget);
    expect(find.text('Tambah Stok'), findsOneWidget);
    expect(find.text('Inventori'), findsOneWidget);
    expect(find.text('WO Baru'), findsNothing);
  });
}
