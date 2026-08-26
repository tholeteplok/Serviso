import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/auth/models/profile.dart';
import 'package:serviso/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('login gagal menampilkan pesan error Indonesia', (tester) async {
    final fake = FakeAuthRepository()..failLogin = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('username')), 'kasir1');
    await tester.enterText(find.byKey(const Key('password')), 'salah');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Username atau password salah'), findsOneWidget);
  });

  testWidgets('login berhasil menyetel sesi aktif', (tester) async {
    const profile = Profile(
      id: 'u1',
      username: 'kasir1',
      fullName: 'Kasir',
      role: UserRole.kasir,
      isActive: true,
    );
    final fake = FakeAuthRepository()..profileToReturn = profile;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('username')), 'kasir1');
    await tester.enterText(find.byKey(const Key('password')), 'benar');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    final current = await fake.currentProfile();
    expect(current, isNotNull);
    expect(current?.username, 'kasir1');
  });
}
