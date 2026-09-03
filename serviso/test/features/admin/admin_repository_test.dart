import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/admin/data/admin_repository.dart';
import 'package:serviso/features/admin/data/audit_log_repository.dart';
import 'package:serviso/features/admin/models/admin_models.dart';
import 'package:serviso/features/auth/models/profile.dart';

void main() {
  group('FakeAdminRepository', () {
    late FakeAdminRepository repo;

    setUp(() {
      repo = FakeAdminRepository();
    });

    test('listUsers returns default profiles', () async {
      final users = await repo.listUsers();
      expect(users.length, 2);
      expect(users.first.username, 'admin');
    });

    test('createUser adds new user to list', () async {
      await repo.createUser(
        const CreateUserPayload(
          username: 'kasir2',
          fullName: 'Budi Kasir Dua',
          role: UserRole.kasir,
          password: 'password123',
        ),
      );
      final users = await repo.listUsers();
      expect(users.length, 3);
      expect(users.last.username, 'kasir2');
    });

    test('toggleUserActive updates profile is_active status', () async {
      await repo.toggleUserActive('u2', false);
      final users = await repo.listUsers();
      final u2 = users.firstWhere((p) => p.id == 'u2');
      expect(u2.isActive, false);
    });
  });

  group('FakeAuditLogRepository', () {
    late FakeAuditLogRepository repo;

    setUp(() {
      repo = FakeAuditLogRepository();
    });

    test('fetchAuditLogs returns mock entries', () async {
      final logs = await repo.fetchAuditLogs();
      expect(logs.length, 3);
      expect(logs.first.tableName, 'parts');
    });

    test('fetchAuditLogs filter by tableName', () async {
      final logs = await repo.fetchAuditLogs(
        filter: const AuditLogFilter(tableName: 'work_orders'),
      );
      expect(logs.length, 1);
      expect(logs.first.tableName, 'work_orders');
    });
  });
}
