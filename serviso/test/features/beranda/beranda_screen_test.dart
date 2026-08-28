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
    expect(find.text('WO Aktif'), findsOneWidget);
    expect(find.text('Stok Menipis'), findsOneWidget);
    expect(find.text('Tren Pendapatan 7 Hari'), findsOneWidget);
    expect(find.text('Aksi Cepat'), findsOneWidget);
  });
}
