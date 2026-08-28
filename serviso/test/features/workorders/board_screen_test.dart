import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/antrian/screens/antrian_screen.dart';
import 'package:serviso/features/workorders/controllers/work_order_providers.dart';
import 'package:serviso/features/workorders/data/fakes.dart';
import 'package:serviso/features/workorders/models/work_order.dart';

Widget _pumpBoard(FakeWorkOrderRepository fake) {
  final container = ProviderContainer(
    overrides: [
      boardControllerProvider.overrideWith((ref) => fake.watchBoard()),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const AntrianScreen(),
    ),
  );
}

void main() {
  group('Antrian board', () {
    testWidgets('menampilkan 3 tab status dan bisa berpindah antar tab', (tester) async {
      final fake = FakeWorkOrderRepository();
      fake.seedPartStock('p1', 20);
      final orders = <WorkOrder>[];
      for (final complaint in ['Ganti oli', 'Servis rem', 'Tune up']) {
        final created = await fake.create(
          WorkOrderDraft(
            vehicleId: 'v1',
            complaint: complaint,
            items: const [],
          ),
        );
        orders.add(created);
      }
      // orders[0] tetap menunggu, orders[1] selesai, orders[2] dikerjakan
      await fake.start(orders[1].id);
      await fake.complete(orders[1].id);
      await fake.start(orders[2].id);

      await tester.pumpWidget(_pumpBoard(fake));
      await tester.pumpAndSettle();

      // Verifikasi 3 tab ada
      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('Dikerjakan'), findsWidgets);
      expect(find.text('Selesai'), findsWidgets);

      // Tab default adalah Menunggu -> 'Ganti oli' terlihat
      expect(find.text('Ganti oli'), findsOneWidget);

      // Tap tab Dikerjakan
      await tester.tap(find.text('Dikerjakan').first);
      await tester.pumpAndSettle();
      expect(find.text('Tune up'), findsOneWidget);

      // Tap tab Selesai
      await tester.tap(find.text('Selesai').first);
      await tester.pumpAndSettle();
      expect(find.text('Servis rem'), findsOneWidget);
    });

    testWidgets('empty state saat tidak ada work order', (tester) async {
      final fake = FakeWorkOrderRepository();
      await tester.pumpWidget(_pumpBoard(fake));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada antrian menunggu'), findsOneWidget);
    });

    testWidgets('toggle filter Hari ini/Semua tidak menyebabkan crash',
        (tester) async {
      final fake = FakeWorkOrderRepository();
      await fake.create(
        const WorkOrderDraft(
          vehicleId: 'v1',
          complaint: 'Lama',
          items: [],
        ),
      );
      await tester.pumpWidget(_pumpBoard(fake));
      await tester.pumpAndSettle();

      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Hari ini'), findsOneWidget);
    });
  });
}
