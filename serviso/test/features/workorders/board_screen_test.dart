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
    testWidgets('menampilkan 3 kolom dengan header status', (tester) async {
      final fake = FakeWorkOrderRepository();
      fake.seedPartStock('p1', 20);
      for (final complaint in ['Ganti oli', 'Servis rem', 'Tune up']) {
        final created = await fake.create(
          WorkOrderDraft(
            vehicleId: 'v1',
            complaint: complaint,
            items: const [],
          ),
        );
        await fake.start(created.id);
      }
      // satu masih menunggu, dua dikerjakan
      final orders = fake.store;
      await fake.start(orders[1].id); // sudah dikerjakan
      await fake.complete(orders[1].id); // selesai
      // orders[0] menunggu, orders[1] selesai, orders[2] dikerjakan

      await tester.pumpWidget(_pumpBoard(fake));
      await tester.pumpAndSettle();

      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('Dikerjakan'), findsWidgets);
      expect(find.text('Selesai'), findsWidgets);
      expect(find.text('Ganti oli'), findsOneWidget);
      expect(find.text('Servis rem'), findsOneWidget);
      expect(find.text('Tune up'), findsOneWidget);
    });

    testWidgets('empty state saat tidak ada work order', (tester) async {
      final fake = FakeWorkOrderRepository();
      await tester.pumpWidget(_pumpBoard(fake));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada work order'), findsWidgets);
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

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    });
  });
}
