import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/auth/models/profile.dart';
import 'package:serviso/features/auth/screens/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen displays shop code, shop name, and copies slug', (tester) async {
    const profile = Profile(
      id: 'u123',
      username: 'budi_admin',
      fullName: 'Budi Hartono',
      role: UserRole.admin,
      isActive: true,
      phone: '08123456789',
      shopId: 'shop-uuid-1',
      shopName: 'Bengkel Jaya Abadi',
      shopSlug: 'jaya-abadi',
    );

    final fakeAuthRepo = FakeAuthRepository()..profileToReturn = profile;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify user info is displayed
    expect(find.text('Budi Hartono'), findsWidgets);
    expect(find.text('@budi_admin'), findsOneWidget);

    // Verify shop info is displayed
    expect(find.text('Kode Toko'), findsOneWidget);
    expect(find.text('jaya-abadi'), findsOneWidget);
    expect(find.text('Nama Toko'), findsOneWidget);
    expect(find.text('Bengkel Jaya Abadi'), findsOneWidget);

    // Verify copy button exists and can be tapped
    final copyButton = find.byKey(const Key('copy_shop_slug'));
    expect(copyButton, findsOneWidget);

    // Test clipboard copy action
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedText = (methodCall.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    expect(copiedText, 'jaya-abadi');
    expect(find.text('Kode toko berhasil disalin'), findsOneWidget);
  });
}
