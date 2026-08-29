// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/inventori/data/fakes.dart';
import 'package:serviso/features/inventori/data/repository_exception.dart';
import 'package:serviso/features/inventori/models/part.dart';
import 'package:serviso/features/inventori/models/part_movement.dart';

void main() {
  group('FakePartRepository contract', () {
    test('stockIn memasukkan movement direction in', () async {
      final repo = FakePartRepository();
      await repo.createPart(
        PartInput(name: 'Oli', minStock: 2),
      );
      final created = (await repo.list()).first;
      await repo.stockIn(created.id, 10, note: 'pembelian');

      final movements = await repo.movements(created.id);
      expect(movements.length, 1);
      expect(movements.first.direction, MovementDirection.in_);
      expect(movements.first.qty, 10);
      expect(movements.first.refType, MovementRef.pembelian);
      expect(movements.first.note, 'pembelian');

      final updated = await repo.getById(created.id);
      expect(updated!.stockQty, 10);
    });

    test('stok konsisten dengan total movement', () async {
      final repo = FakePartRepository();
      final part = await repo.createPart(PartInput(name: 'Busi'));
      await repo.stockIn(part.id, 20);
      await repo.adjustStock(part.id, -5, 'koreksi');
      await repo.stockIn(part.id, 3);

      final movements = await repo.movements(part.id);
      final sum = movements.fold(
        0.0,
        (s, m) => s + m.signedDelta,
      );
      final current = (await repo.getById(part.id))!;
      expect(sum, current.stockQty);
      expect(current.stockQty, 18);
    });

    test('adjustStock tanpa alasan melempar', () async {
      final repo = FakePartRepository();
      final part = await repo.createPart(PartInput(name: 'Kampas'));
      await repo.stockIn(part.id, 5);

      expect(
        () => repo.adjustStock(part.id, -1, ''),
        throwsA(isA<RepositoryException>()),
      );
      expect(
        () => repo.adjustStock(part.id, -1, '   '),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('adjustStock menghasilkan movement direction adjust', () async {
      final repo = FakePartRepository();
      final part = await repo.createPart(PartInput(name: 'Filter'));
      await repo.stockIn(part.id, 5);

      await repo.adjustStock(part.id, -2, 'rusak');

      final movements = await repo.movements(part.id);
      final adjust = movements.first;
      expect(adjust.direction, MovementDirection.adjust);
      expect(adjust.qty, -2);
      expect(adjust.refType, MovementRef.koreksi);
      expect(adjust.note, 'rusak');
      expect((await repo.getById(part.id))!.stockQty, 3);
    });

    test('adjustStock cegah stok negatif (mirror CHECK DB)', () async {
      final repo = FakePartRepository();
      final part = await repo.createPart(PartInput(name: 'Talang'));
      await repo.stockIn(part.id, 2);

      expect(
        () => repo.adjustStock(part.id, -5, 'salah hitung'),
        throwsA(isA<RepositoryException>()),
      );
      expect((await repo.getById(part.id))!.stockQty, 2);
    });

    test('list filterLowStock hanya mengembalikan stok menipis', () async {
      final repo = FakePartRepository();
      final low = await repo.createPart(PartInput(name: 'A', minStock: 5));
      await repo.stockIn(low.id, 2);
      final ok = await repo.createPart(PartInput(name: 'B', minStock: 1));
      await repo.stockIn(ok.id, 20);

      final lowOnly = await repo.list(filterLowStock: true);
      expect(lowOnly.length, 1);
      expect(lowOnly.first.id, low.id);
    });

    test('list search mencocokkan nama & kode', () async {
      final repo = FakePartRepository();
      await repo.createPart(PartInput(name: 'Oli Mesin', code: 'P001'));
      await repo.createPart(PartInput(name: 'Busi', code: 'P002'));

      final byName = await repo.list(search: 'oli');
      expect(byName.length, 1);
      expect(byName.first.code, 'P001');

      final byCode = await repo.list(search: 'p002');
      expect(byCode.length, 1);
      expect(byCode.first.name, 'Busi');
    });

    test('stockIn dengan distributor, purchasePrice, dan hutang mencatat status belum_lunas', () async {
      final repo = FakePartRepository();
      final part = await repo.createPart(PartInput(name: 'Oli Top 1', costPrice: 40000));
      await repo.stockIn(
        part.id,
        10,
        distributor: 'PT Sumber Makmur',
        purchasePrice: 45000,
        paymentType: 'hutang',
        dueDate: DateTime.now().add(const Duration(days: 14)),
        updateCostPrice: true,
      );

      final movements = await repo.movements(part.id);
      expect(movements.first.distributor, 'PT Sumber Makmur');
      expect(movements.first.purchasePrice, 45000);
      expect(movements.first.paymentType, 'hutang');
      expect(movements.first.debtStatus, 'belum_lunas');
      expect(movements.first.isUnpaidDebt, isTrue);
      expect(movements.first.totalPurchaseAmount, 450000);

      // Verify master cost price was updated
      final updated = await repo.getById(part.id);
      expect(updated!.costPrice, 45000);

      // Verify outstanding debts query
      final debts = await repo.getOutstandingDebts();
      expect(debts.length, 1);
      expect(debts.first.distributor, 'PT Sumber Makmur');

      // Pay debt
      await repo.markDebtPaid(debts.first.id);
      final remainingDebts = await repo.getOutstandingDebts();
      expect(remainingDebts, isEmpty);
    });

    test('createPart dengan initialStock dan distributor otomatis mencatat stok awal dan mutasi', () async {
      final repo = FakePartRepository();
      final created = await repo.createPart(
        PartInput(
          name: 'Oli Mesin Matic',
          code: 'OL-001',
          initialStock: 15,
          distributor: 'Distributor A',
          costPrice: 50000,
          paymentType: 'hutang',
        ),
      );

      // Verify stock
      expect(created.stockQty, 15);

      // Verify movements
      final movements = await repo.movements(created.id);
      expect(movements.length, 1);
      expect(movements.first.distributor, 'Distributor A');
      expect(movements.first.qty, 15);
      expect(movements.first.purchasePrice, 50000);
      expect(movements.first.paymentType, 'hutang');
      expect(movements.first.debtStatus, 'belum_lunas');
    });

    test('part yang sama dapat dibeli dari 2 distributor berbeda', () async {
      final repo = FakePartRepository();
      // Pembelian 1: Distributor A (10 pcs, tunai)
      final part = await repo.createPart(
        PartInput(
          name: 'Oli MPX 2',
          code: 'MPX2',
          initialStock: 10,
          distributor: 'Distributor A',
          costPrice: 48000,
          paymentType: 'tunai',
        ),
      );

      // Pembelian 2: Distributor B (20 pcs, hutang)
      await repo.stockIn(
        part.id,
        20,
        distributor: 'Distributor B',
        purchasePrice: 47000,
        paymentType: 'hutang',
      );

      // Total stok = 10 + 20 = 30
      final updated = await repo.getById(part.id);
      expect(updated!.stockQty, 30);

      // Movements memiliki 2 entri dengan distributor berbeda
      final movements = await repo.movements(part.id);
      expect(movements.length, 2);
      expect(movements[0].distributor, 'Distributor B');
      expect(movements[0].qty, 20);
      expect(movements[1].distributor, 'Distributor A');
      expect(movements[1].qty, 10);

      // Hutang hanya mencatat pembelian dari Distributor B
      final debts = await repo.getOutstandingDebts();
      expect(debts.length, 1);
      expect(debts.first.distributor, 'Distributor B');
      expect(debts.first.totalPurchaseAmount, 940000);
    });
  });
}
