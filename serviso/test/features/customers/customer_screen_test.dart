import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/auth/data/auth_repository.dart';
import 'package:serviso/features/customers/controllers/customer_providers.dart';
import 'package:serviso/features/customers/data/fakes.dart';
import 'package:serviso/features/customers/models/customer.dart';
import 'package:serviso/features/customers/models/vehicle.dart';
import 'package:serviso/features/customers/screens/customer_detail_screen.dart';
import 'package:serviso/features/customers/screens/customer_list_screen.dart';

Widget _pumpList({
  required FakeCustomerRepository customers,
  bool isAdmin = false,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      customerRepositoryProvider.overrideWithValue(customers),
      isAdminProvider.overrideWithValue(isAdmin),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const CustomerListScreen(),
    ),
  );
}

void main() {
  group('CustomerListScreen', () {
    testWidgets('empty state menampilkan ajakan Tambah Pelanggan',
        (tester) async {
      await tester.pumpWidget(
        _pumpList(customers: FakeCustomerRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pelanggan'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Tambah Pelanggan'),
          findsOneWidget);
    });

    testWidgets('render daftar pelanggan dengan nama & jumlah kendaraan',
        (tester) async {
      final fake = FakeCustomerRepository(
        initial: [
          Customer(
            id: 'c1',
            name: 'Budi Santoso',
            phone: '0812',
            vehicleCount: 2,
            createdAt: DateTime.now(),
          ),
          Customer(
            id: 'c2',
            name: 'Candra',
            vehicleCount: 0,
            createdAt: DateTime.now(),
          ),
        ],
      );
      await tester.pumpWidget(_pumpList(customers: fake));
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Candra'), findsOneWidget);
      expect(find.text('2 kendaraan'), findsOneWidget);
      expect(find.text('0 kendaraan'), findsOneWidget);
    });
  });

  group('CustomerDetailScreen admin-delete gate', () {
    Widget buildDetail({required bool isAdmin}) {
      final customers = FakeCustomerRepository(
        initial: [
          Customer(
            id: 'c1',
            name: 'Budi Santoso',
            createdAt: DateTime.now(),
          ),
        ],
      );
      final vehicles = FakeVehicleRepository(
        initial: [
          Vehicle(
            id: 'v1',
            customerId: 'c1',
            plateNo: 'B 1234 ABC',
            createdAt: DateTime.now(),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          customerRepositoryProvider.overrideWithValue(customers),
          vehicleRepositoryProvider.overrideWithValue(vehicles),
          isAdminProvider.overrideWithValue(isAdmin),
        ],
      );
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CustomerDetailScreen(customerId: 'c1'),
        ),
      );
    }

    testWidgets('isAdmin false menyembunyikan tombol hapus pelanggan',
        (tester) async {
      await tester.pumpWidget(buildDetail(isAdmin: false));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hapus pelanggan'), findsNothing);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('B 1234 ABC'), findsOneWidget);
    });

    testWidgets('isAdmin true menampilkan tombol hapus pelanggan',
        (tester) async {
      await tester.pumpWidget(buildDetail(isAdmin: true));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hapus pelanggan'), findsOneWidget);
    });
  });
}
