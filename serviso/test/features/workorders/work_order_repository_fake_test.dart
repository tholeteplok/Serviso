import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/models/wo_status.dart';
import 'package:serviso/features/workorders/data/fakes.dart';
import 'package:serviso/features/workorders/data/repository_exception.dart';
import 'package:serviso/features/workorders/models/work_order.dart';

void main() {
  group('FakeWorkOrderRepository status flow', () {
    late FakeWorkOrderRepository fake;

    setUp(() {
      fake = FakeWorkOrderRepository();
      fake.seedPartStock('p1', 10);
    });

    Future<String> makeCreated({bool withPart = true}) async {
      final draft = WorkOrderDraft(
        vehicleId: 'v1',
        complaint: 'Service berkala',
        items: withPart
            ? const [
                WoItemInput(
                  kind: WoItemKind.part,
                  partId: 'p1',
                  partName: 'Oli',
                  qty: 3,
                  unitPrice: 50000,
                ),
              ]
            : const [],
      );
      final created = await fake.create(draft);
      return created.id;
    }

    test('create -> status menunggu dengan wo_number otomatis', () async {
      final id = await makeCreated();
      final order = await fake.getById(id);
      expect(order!.status, WoStatus.menunggu);
      expect(order.woNumber.startsWith('WO-'), isTrue);
    });

    test('start mengubah menunggu -> dikerjakan', () async {
      final id = await makeCreated();
      await fake.start(id);
      final order = await fake.getById(id);
      expect(order!.status, WoStatus.dikerjakan);
    });

    test('complete menunggu throws (harus dikerjakan dulu)', () async {
      final id = await makeCreated();
      expect(() => fake.complete(id), throwsA(isA<RepositoryException>()));
    });

    test('complete: stok berkurang & mencatat movement out ref wo', () async {
      final id = await makeCreated();
      await fake.start(id);
      await fake.complete(id);
      final order = await fake.getById(id);
      expect(order!.status, WoStatus.selesai);
      expect(fake.ledger.where((l) => l.direction == 'out' && l.refType == 'wo'),
          isNotEmpty);
      // stok 10 - 3 = 7
      expect(fake.ledger
          .where((l) => l.partId == 'p1')
          .fold(10.0, (s, l) => s + (l.direction == 'out' ? -l.qty : l.qty)),
          closeTo(7.0, 0.001));
    });

    test('cancel selesai: reversal in ref pembatalan & stok kembali', () async {
      final id = await makeCreated();
      await fake.start(id);
      await fake.complete(id);
      await fake.cancel(id);
      final order = await fake.getById(id);
      expect(order!.status, WoStatus.dibatalkan);
      expect(
        fake.ledger
            .where((l) => l.direction == 'in' && l.refType == 'pembatalan'),
        isNotEmpty,
      );
      // stok kembali ke 10
      expect(fake.ledger
          .where((l) => l.partId == 'p1')
          .fold(10.0, (s, l) => s + (l.direction == 'out' ? -l.qty : l.qty)),
          closeTo(10.0, 0.001));
    });

    test('cancel menunggu tanpa reversal (belum ada stok keluar)', () async {
      final id = await makeCreated(withPart: false);
      await fake.cancel(id);
      final order = await fake.getById(id);
      expect(order!.status, WoStatus.dibatalkan);
      expect(
        fake.ledger.where((l) => l.refType == 'pembatalan'),
        isEmpty,
      );
    });

    test('cancel pada dibatalkan throws (terminal)', () async {
      final id = await makeCreated(withPart: false);
      await fake.cancel(id);
      expect(() => fake.cancel(id), throwsA(isA<RepositoryException>()));
    });

    test('complete gagal bila stok tidak cukup', () async {
      final fakeLow = FakeWorkOrderRepository();
      fakeLow.seedPartStock('p1', 1);
      final draft = const WorkOrderDraft(
        vehicleId: 'v1',
        complaint: 'Service',
        items: [
          WoItemInput(
            kind: WoItemKind.part,
            partId: 'p1',
            qty: 5,
            unitPrice: 1000,
          ),
        ],
      );
      final created = await fakeLow.create(draft);
      await fakeLow.start(created.id);
      expect(() => fakeLow.complete(created.id),
          throwsA(isA<RepositoryException>()));
    });

    test('addItem/removeItem hanya saat menunggu/dikerjakan', () async {
      final id = await makeCreated();
      await fake.addItem(
        id,
        const WoItemInput(
          kind: WoItemKind.jasa,
          description: 'Ganti busi',
          qty: 1,
          unitPrice: 20000,
        ),
      );
      var order = await fake.getById(id);
      expect(order!.items.length, 2);

      await fake.start(id);
      await fake.complete(id);
      expect(
        () => fake.addItem(
          id,
          const WoItemInput(kind: WoItemKind.jasa, description: 'x', qty: 1, unitPrice: 1),
        ),
        throwsA(isA<RepositoryException>()),
      );
      final current = await fake.getById(id);
      expect(
        () => fake.removeItem(id, current!.items.first.id),
        throwsA(isA<RepositoryException>()),
      );
    });
  });
}
