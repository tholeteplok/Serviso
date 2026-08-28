import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/admin/controllers/admin_controllers.dart';
import 'package:serviso/features/admin/data/audit_log_repository.dart';
import 'package:serviso/features/admin/screens/audit_log_screen.dart';

void main() {
  testWidgets('AuditLogScreen renders filters & audit log cards', (tester) async {
    final fakeAuditRepo = FakeAuditLogRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auditLogRepositoryProvider.overrideWithValue(fakeAuditRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AuditLogScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Audit Log Sistem'), findsOneWidget);
    expect(find.text('parts'), findsOneWidget);
    expect(find.text('work_orders'), findsOneWidget);
    expect(find.text('auth'), findsOneWidget);
  });
}
