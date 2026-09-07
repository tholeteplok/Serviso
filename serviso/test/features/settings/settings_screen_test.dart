import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/auth/models/profile.dart';
import 'package:serviso/features/settings/data/settings_repository.dart';
import 'package:serviso/features/settings/screens/settings_screen.dart';
import 'package:serviso/features/settings/screens/shop_settings_screen.dart';

void main() {
  group('ShopSettingsScreen', () {
    testWidgets('loads existing settings and saves updated receipt notes and business type', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSettingsRepo = FakeSettingsRepository();
      await fakeSettingsRepo.updateSettings(
        shopName: 'Bengkel Maju',
        address: 'Jl. Merdeka 10',
        phone: '0812345678',
        receiptNotes: 'Garansi servis 7 hari.',
        businessType: 'keduanya',
      );

      const adminProfile = Profile(
        id: 'admin1',
        username: 'admin',
        fullName: 'Owner',
        role: UserRole.admin,
        isActive: true,
        shopBusinessType: 'keduanya',
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
            home: const ShopSettingsScreen(),
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

      // Tap save button
      final saveButton = find.byKey(const Key('save_settings_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check repository updated
      final currentSettings = await fakeSettingsRepo.getSettings();
      expect(currentSettings.receiptNotes, 'Garansi servis 14 hari. Simpan nota ini.');
      expect(currentSettings.shopName, 'Bengkel Maju');
      expect(currentSettings.businessType, 'keduanya');
    });

    testWidgets('blocks non-admin users', (tester) async {
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
            home: const ShopSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hanya pemilik yang dapat mengubah pengaturan toko.'), findsOneWidget);
      expect(find.byKey(const Key('receipt_notes_field')), findsNothing);
    });

    testWidgets('changes business type to Jual Barang with save confirmation dialog and hides Mode Jasa', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSettingsRepo = FakeSettingsRepository();
      await fakeSettingsRepo.updateSettings(
        shopName: 'Toko Serba Ada',
        businessType: 'keduanya',
        serviceMode: 'otomotif',
      );

      const adminProfile = Profile(
        id: 'admin1',
        username: 'admin',
        fullName: 'Owner',
        role: UserRole.admin,
        isActive: true,
        shopBusinessType: 'keduanya',
        shopServiceMode: 'otomotif',
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
            home: const ShopSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mode Jasa is visible initially because businessType is 'keduanya'
      expect(find.text('Mode Jasa'), findsOneWidget);

      // Tap "Jual Barang"
      await tester.tap(find.text('Jual Barang'));
      await tester.pumpAndSettle();

      // Verify no modal dialog pops up immediately on segment tap
      expect(find.text('Ubah Jenis Usaha?'), findsNothing);

      // Mode Jasa is now hidden because retail does not have services
      expect(find.text('Mode Jasa'), findsNothing);

      // Tap Save
      final saveButton = find.byKey(const Key('save_settings_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear on save
      expect(find.text('Ubah Jenis Usaha?'), findsOneWidget);
      await tester.tap(find.text('Ubah & Simpan'));
      await tester.pumpAndSettle();

      // Verify saved in repository
      final saved = await fakeSettingsRepo.getSettings();
      expect(saved.businessType, 'barang');
    });

    testWidgets('changes service mode to Umum and saves successfully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSettingsRepo = FakeSettingsRepository();
      await fakeSettingsRepo.updateSettings(
        shopName: 'Bengkel & Servis AC',
        businessType: 'keduanya',
        serviceMode: 'otomotif',
      );

      const adminProfile = Profile(
        id: 'admin1',
        username: 'admin',
        fullName: 'Owner',
        role: UserRole.admin,
        isActive: true,
        shopBusinessType: 'keduanya',
        shopServiceMode: 'otomotif',
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
            home: const ShopSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Umum (Non-Kendaraan)
      expect(find.text('Umum (Non-Kendaraan)'), findsOneWidget);
      await tester.tap(find.text('Umum (Non-Kendaraan)'));
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.byKey(const Key('save_settings_button'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify saved
      final saved = await fakeSettingsRepo.getSettings();
      expect(saved.serviceMode, 'umum');
      expect(saved.businessType, 'keduanya');
    });
  });

  group('SettingsScreen (Hub)', () {
    testWidgets('renders user profile summary and administration section for admin', (tester) async {
      const adminProfile = Profile(
        id: 'admin1',
        username: 'owner_bengkel',
        fullName: 'Budi Owner',
        role: UserRole.admin,
        isActive: true,
      );
      final fakeAuthRepo = FakeAuthRepository()..profileToReturn = adminProfile;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profile summary card
      expect(find.text('Budi Owner'), findsOneWidget);
      expect(find.text('@owner_bengkel'), findsOneWidget);
      expect(find.text('Pemilik (Admin)'), findsOneWidget);

      // Administration section
      expect(find.text('Administrasi'), findsOneWidget);
      expect(find.text('Profil & Jenis Usaha Toko'), findsOneWidget);
      expect(find.text('Kelola Pengguna'), findsOneWidget);
      expect(find.text('Audit Log Sistem'), findsOneWidget);

      // Logout button
      expect(find.byKey(const Key('hub_logout_button')), findsOneWidget);
    });

    testWidgets('hides administration section for cashier role', (tester) async {
      const kasirProfile = Profile(
        id: 'kasir1',
        username: 'siti_kasir',
        fullName: 'Siti Kasir',
        role: UserRole.kasir,
        isActive: true,
      );
      final fakeAuthRepo = FakeAuthRepository()..profileToReturn = kasirProfile;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profile summary card
      expect(find.text('Siti Kasir'), findsOneWidget);
      expect(find.text('@siti_kasir'), findsOneWidget);
      expect(find.text('Kasir'), findsOneWidget);

      // Administration section must NOT be visible
      expect(find.text('Administrasi'), findsNothing);
      expect(find.text('Profil & Jenis Usaha Toko'), findsNothing);

      // Logout button still visible
      expect(find.byKey(const Key('hub_logout_button')), findsOneWidget);
    });
  });
}
