import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/auth/models/profile.dart';
import 'package:serviso/features/settings/data/settings_repository.dart';
import 'package:serviso/features/settings/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen loads existing settings and saves updated receipt notes', (tester) async {
    final fakeSettingsRepo = FakeSettingsRepository();
    await fakeSettingsRepo.updateSettings(
      shopName: 'Bengkel Maju',
      address: 'Jl. Merdeka 10',
      phone: '0812345678',
      receiptNotes: 'Garansi servis 7 hari.',
    );

    const adminProfile = Profile(
      id: 'admin1',
      username: 'admin',
      fullName: 'Owner',
      role: UserRole.admin,
      isActive: true,
    );
    final fakeAuthRepo = FakeAuthRepository()..profileToReturn = adminProfile;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial values populated
    expect(find.text('Bengkel Maju'), findsOneWidget);
    expect(find.text('Jl. Merdeka 10'), findsOneWidget);
    expect(find.text('0812345678'), findsOneWidget);
    expect(find.text('Garansi servis 7 hari.'), findsOneWidget);

    // Edit receipt notes
    final notesField = find.byKey(const Key('receipt_notes_field'));
    expect(notesField, findsOneWidget);

    await tester.enterText(notesField, 'Garansi servis 14 hari. Simpan nota ini.');
    await tester.pumpAndSettle();

    // Scroll down to save button and tap
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final saveButton = find.text('Simpan Pengaturan');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Check repository updated
    final currentSettings = await fakeSettingsRepo.getSettings();
    expect(currentSettings.receiptNotes, 'Garansi servis 14 hari. Simpan nota ini.');
    expect(currentSettings.shopName, 'Bengkel Maju');
  });

  testWidgets('SettingsScreen blocks non-admin users', (tester) async {
    final fakeSettingsRepo = FakeSettingsRepository();
    const kasirProfile = Profile(
      id: 'kasir1',
      username: 'kasir',
      fullName: 'Kasir',
      role: UserRole.kasir,
      isActive: true,
    );
    final fakeAuthRepo = FakeAuthRepository()..profileToReturn = kasirProfile;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hanya pemilik yang dapat mengubah pengaturan toko'), findsOneWidget);
    expect(find.byKey(const Key('receipt_notes_field')), findsNothing);
  });
}
