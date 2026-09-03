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
}
