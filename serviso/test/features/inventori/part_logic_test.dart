import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/inventori/models/part.dart';
import 'package:serviso/features/inventori/part_logic.dart';

Part _part({double stock = 5, int min = 2}) => Part(
      id: 'p1',
      name: 'Oli',
      stockQty: stock,
      minStock: min,
      createdAt: DateTime.now(),
    );

void main() {
  group('low-stock badge logic', () {
    test('stok <= min_stock -> isLowStock true', () {
      expect(_part(stock: 2, min: 2).isLowStock, isTrue);
      expect(_part(stock: 1, min: 2).isLowStock, isTrue);
    });

    test('stok > min_stock -> isLowStock false', () {
      expect(_part(stock: 3, min: 2).isLowStock, isFalse);
    });
  });

  group('adjustStock preview & negative guard', () {
    test('preview hasil = stok + delta', () {
      expect(previewAdjustStock(10, -3), 7);
      expect(previewAdjustStock(10, 0), 10);
      expect(previewAdjustStock(10, 4), 14);
    });

    test('canAdjustStock false bila hasil < 0', () {
      expect(canAdjustStock(5, -5), isTrue);
      expect(canAdjustStock(5, -6), isFalse);
      expect(canAdjustStock(0, -1), isFalse);
    });
  });
}
