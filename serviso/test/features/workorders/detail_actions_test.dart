import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/models/wo_status.dart';
import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/workorders/controllers/work_order_providers.dart';
import 'package:serviso/features/workorders/data/fakes.dart';
import 'package:serviso/features/workorders/models/work_order.dart';
import 'package:serviso/features/workorders/screens/wo_detail_screen.dart';

Future<String> _seed(FakeWorkOrderRepository fake, WoStatus status) async {
  fake.seedPartStock('p1', 50);
  final created = await fake.create(
    const WorkOrderDraft(
      vehicleId: 'v1',
      complaint: 'Keluhan',
      items: [
        WoItemInput(
          kind: WoItemKind.part,
          partId: 'p1',
          partName: 'Oli',
          qty: 2,
          unitPrice: 50000,
        ),
      ],
    ),
  );
  switch (status) {
    case WoStatus.menunggu:
      break;
    case WoStatus.dikerjakan:
      await fake.start(created.id);
    case WoStatus.selesai:
      await fake.start(created.id);
      await fake.complete(created.id);
    case WoStatus.dibatalkan:
      await fake.cancel(created.id);
  }
  return created.id;
}

Widget _pumpDetail({
  required FakeWorkOrderRepository fake,
  required String id,
  required bool isAdmin,
}) {
  final container = ProviderContainer(
    overrides: [
      workOrderRepositoryProvider.overrideWithValue(fake),
      isAdminProvider.overrideWithValue(isAdmin),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: WoDetailScreen(workOrderId: id),
    ),
  );
}

void main() {
  group('Detail WO aksi berdasar status & role', () {
    testWidgets('menunggu + kasir: Mulai Kerja & Batalkan', (tester) async {
      final fake = FakeWorkOrderRepository();
      final id = await _seed(fake, WoStatus.menunggu);
      await tester.pumpWidget(_pumpDetail(fake: fake, id: id, isAdmin: false));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Mulai Kerja'), findsOneWidget);
      expect(find.text('Batalkan'), findsOneWidget);
      expect(find.text('Batalkan (kembalikan stok)'), findsNothing);
      expect(find.text('Selesaikan'), findsNothing);
    });

    testWidgets('dikerjakan + kasir: Selesaikan & Batalkan', (tester) async {
      final fake = FakeWorkOrderRepository();
      final id = await _seed(fake, WoStatus.dikerjakan);
      await tester.pumpWidget(_pumpDetail(fake: fake, id: id, isAdmin: false));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Selesaikan'), findsOneWidget);
      expect(find.text('Batalkan'), findsOneWidget);
      expect(find.text('Batalkan (kembalikan stok)'), findsNothing);
      expect(find.text('Mulai Kerja'), findsNothing);
    });

    testWidgets('selesai + kasir: tidak ada tombol (Batalkan admin-only)',
        (tester) async {
      final fake = FakeWorkOrderRepository();
      final id = await _seed(fake, WoStatus.selesai);
      await tester.pumpWidget(_pumpDetail(fake: fake, id: id, isAdmin: false));
      await tester.pumpAndSettle();
      expect(find.text('Selesaikan'), findsNothing);
      expect(find.text('Mulai Kerja'), findsNothing);
      expect(find.text('Batalkan'), findsNothing);
      expect(find.text('Batalkan (kembalikan stok)'), findsNothing);
    });

    testWidgets('selesai + admin: Batalkan dengan peringatan pembalikan stok',
        (tester) async {
      final fake = FakeWorkOrderRepository();
      final id = await _seed(fake, WoStatus.selesai);
      await tester.pumpWidget(_pumpDetail(fake: fake, id: id, isAdmin: true));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan (kembalikan stok)'), findsOneWidget);
      expect(find.text('Batalkan'), findsNothing);
    });

    testWidgets('dibatalkan: tidak ada aksi', (tester) async {
      final fake = FakeWorkOrderRepository();
      final id = await _seed(fake, WoStatus.dibatalkan);
      await tester.pumpWidget(_pumpDetail(fake: fake, id: id, isAdmin: true));
      await tester.pumpAndSettle();
      expect(find.text('Mulai Kerja'), findsNothing);
      expect(find.text('Selesaikan'), findsNothing);
      expect(find.text('Batalkan'), findsNothing);
    });
  });
}
