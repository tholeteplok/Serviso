import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/inventori/models/part.dart';
import 'package:serviso/features/inventori/models/part_movement.dart';

void main() {
  group('Part.fromMap', () {
    test('memetakan field termasuk stock_qty & harga', () {
      final p = Part.fromMap({
        'id': 'p1',
        'name': 'Oli Mesin',
        'code': 'P0001',
        'unit': 'botol',
        'min_stock': 3,
        'cost_price': '12000',
        'sell_price': '15000.5',
        'stock_qty': '7.5',
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(p.id, 'p1');
      expect(p.name, 'Oli Mesin');
      expect(p.code, 'P0001');
      expect(p.unit, 'botol');
      expect(p.minStock, 3);
      expect(p.costPrice, 12000);
      expect(p.sellPrice, 15000.5);
      expect(p.stockQty, 7.5);
      expect(p.isLowStock, isFalse);
    });

    test('numeric dikirim sbg num & string tetap terbaca', () {
      final p = Part.fromMap({
        'id': 'p2',
        'name': 'Busi',
        'min_stock': 0,
        'cost_price': 0,
        'sell_price': 0,
        'stock_qty': 0,
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(p.stockQty, 0);
      expect(p.costPrice, 0);
    });

    test('stok <= min_stock -> isLowStock jika min_stock > 0', () {
      final p = Part.fromMap({
        'id': 'p3',
        'name': 'Kampas',
        'min_stock': 4,
        'cost_price': 0,
        'sell_price': 0,
        'stock_qty': 2,
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(p.isLowStock, isTrue);
      expect(p.isOutOfStock, isFalse);
    });

    test('stok > min_stock -> isLowStock false', () {
      final p = Part.fromMap({
        'id': 'p4',
        'name': 'Oli Gardan',
        'min_stock': 5,
        'cost_price': 0,
        'sell_price': 0,
        'stock_qty': 10,
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(p.isLowStock, isFalse);
      expect(p.isOutOfStock, isFalse);
    });

    test('min_stock 0 (tidak disetel batas) -> isLowStock tetap false meski stok 0', () {
      final p = Part.fromMap({
        'id': 'p5',
        'name': 'Baut',
        'min_stock': 0,
        'cost_price': 0,
        'sell_price': 0,
        'stock_qty': 0,
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(p.isLowStock, isFalse);
      expect(p.isOutOfStock, isTrue);
    });
  });

  group('PartMovement.fromMap', () {
    test('memetakan direction, qty, ref, dan actor via join profiles', () {
      final m = PartMovement.fromMap({
        'id': 'm1',
        'part_id': 'p1',
        'direction': 'adjust',
        'qty': '-2.5',
        'ref_type': 'koreksi',
        'note': 'rusak',
        'created_at': '2025-01-02T03:04:05.000Z',
        'profiles': {'full_name': 'Budi'},
      });
      expect(m.direction, MovementDirection.adjust);
      expect(m.qty, -2.5);
      expect(m.refType, MovementRef.koreksi);
      expect(m.actorName, 'Budi');
      expect(m.signedDelta, -2.5);
    });

    test('direction in -> signedDelta positif', () {
      final m = PartMovement.fromMap({
        'id': 'm2',
        'part_id': 'p1',
        'direction': 'in',
        'qty': '10',
        'ref_type': 'pembelian',
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(m.signedDelta, 10);
      expect(m.actorName, isNull);
    });
  });

  group('signedQuantity rendering', () {
    String formatSigned(double value) {
      final sign = value >= 0 ? '+' : '-';
      final abs = value.abs();
      final normalized = abs.truncateToDouble() == abs
          ? abs.toInt().toString()
          : abs.toString();
      return '$sign$normalized';
    }

    test('in +3 -> "+3"', () {
      final m = PartMovement.fromMap({
        'id': 'a',
        'part_id': 'p',
        'direction': 'in',
        'qty': '3',
        'ref_type': 'pembelian',
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(formatSigned(m.signedQuantity), '+3');
    });

    test('out +3 -> "-3"', () {
      final m = PartMovement.fromMap({
        'id': 'b',
        'part_id': 'p',
        'direction': 'out',
        'qty': '3',
        'ref_type': 'wo',
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(formatSigned(m.signedQuantity), '-3');
    });

    test('adjust -5 -> "-5"', () {
      final m = PartMovement.fromMap({
        'id': 'c',
        'part_id': 'p',
        'direction': 'adjust',
        'qty': '-5',
        'ref_type': 'koreksi',
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(formatSigned(m.signedQuantity), '-5');
    });

    test('adjust +3 -> "+3"', () {
      final m = PartMovement.fromMap({
        'id': 'd',
        'part_id': 'p',
        'direction': 'adjust',
        'qty': '3',
        'ref_type': 'koreksi',
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(formatSigned(m.signedQuantity), '+3');
    });
  });
}
