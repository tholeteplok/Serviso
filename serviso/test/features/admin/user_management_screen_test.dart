import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/core/widgets/thick_bottom_border_button.dart';
import 'package:serviso/features/admin/controllers/admin_controllers.dart';
import 'package:serviso/features/admin/data/admin_repository.dart';
import 'package:serviso/features/admin/screens/user_management_screen.dart';

void main() {
  testWidgets('UserManagementScreen renders user list & FAB', (tester) async {
    final fakeAdminRepo = FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeAdminRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const UserManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kelola Pengguna'), findsOneWidget);
    expect(find.text('@admin'), findsOneWidget);
    expect(find.text('@kasir1'), findsOneWidget);
    expect(find.widgetWithText(ThickBottomBorderButton, 'Tambah User'), findsOneWidget);
  });

  testWidgets('Add user validates short username with informative dialog', (tester) async {
    final fakeAdminRepo = FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeAdminRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const UserManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open Add User bottom sheet
    await tester.tap(find.widgetWithText(ThickBottomBorderButton, 'Tambah User'));
    await tester.pumpAndSettle();

    // Fill in invalid short username
    await tester.enterText(find.byKey(const Key('input_username')), 'ab');
    await tester.enterText(find.byKey(const Key('input_fullname')), 'Andi Budi');
    await tester.enterText(find.byKey(const Key('input_password')), 'secret123');

    // Tap Simpan Pengguna
    await tester.tap(find.text('Simpan Pengguna'));
    await tester.pumpAndSettle();

    // Verify informative error dialog appears
    expect(find.text('Format Username Tidak Valid'), findsOneWidget);
    expect(find.text('Perbaiki Data'), findsOneWidget);
  });

  testWidgets('Add user duplicate username displays clear error dialog from repository', (tester) async {
    final fakeAdminRepo = FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeAdminRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const UserManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open Add User bottom sheet
    await tester.tap(find.widgetWithText(ThickBottomBorderButton, 'Tambah User'));
    await tester.pumpAndSettle();

    // Fill in duplicate username 'admin'
    await tester.enterText(find.byKey(const Key('input_username')), 'admin');
    await tester.enterText(find.byKey(const Key('input_fullname')), 'Admin Duplikat');
    await tester.enterText(find.byKey(const Key('input_password')), 'secret123');

    // Tap Simpan Pengguna
    await tester.tap(find.text('Simpan Pengguna'));
    await tester.pumpAndSettle();

    // Verify transparent error dialog appears with exact reason
    expect(find.text('Gagal Menambahkan Pengguna'), findsOneWidget);
    expect(find.text("Username 'admin' sudah digunakan."), findsOneWidget);
    expect(find.text('Perbaiki Data'), findsOneWidget);
  });

  testWidgets('Reset pass button opens direct set password dialog and updates password', (tester) async {
    final fakeAdminRepo = FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(fakeAdminRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const UserManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap first Reset Pass button
    await tester.tap(find.text('Reset Pass').first);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Setel Password Baru'), findsOneWidget);
    expect(find.text('Simpan Password'), findsOneWidget);

    // Enter short password (< 6 chars) and verify validation
    await tester.enterText(find.byKey(const Key('input_reset_password')), '12345');
    await tester.tap(find.text('Simpan Password'));
    await tester.pumpAndSettle();
    expect(find.text('Password baru minimal 6 karakter.'), findsOneWidget);

    // Enter valid new password
    await tester.enterText(find.byKey(const Key('input_reset_password')), 'kasirBaru123');
    await tester.tap(find.text('Simpan Password'));
    await tester.pumpAndSettle();

    // Verify success dialog appears
    expect(find.text('Password Berhasil Diubah'), findsOneWidget);
    expect(find.text('Salin'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);

    // Tap Selesai
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Password Berhasil Diubah'), findsNothing);

    // Verify password was updated in repo
    expect(fakeAdminRepo.mockPasswords['u1'], 'kasirBaru123');
  });
}
