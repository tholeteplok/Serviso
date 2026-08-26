import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/customers/controllers/validators.dart';
import 'package:serviso/features/customers/models/customer.dart';
import 'package:serviso/features/customers/models/vehicle.dart';

void main() {
  group('validators', () {
    test('validateCustomerName kosong -> error', () {
      expect(validateCustomerName(null), isNotNull);
      expect(validateCustomerName(''), isNotNull);
      expect(validateCustomerName('   '), isNotNull);
      expect(validateCustomerName('Budi'), isNull);
    });

    test('validatePlate kosong -> error', () {
      expect(validatePlate(null), isNotNull);
      expect(validatePlate(''), isNotNull);
      expect(validatePlate('  '), isNotNull);
      expect(validatePlate('b 1234 abc'), isNull);
    });

    test('validateCustomerPhone opsional & longgar', () {
      expect(validateCustomerPhone(''), isNull);
      expect(validateCustomerPhone(null), isNull);
      expect(validateCustomerPhone('0812'), isNotNull);
      expect(validateCustomerPhone('08123456789'), isNull);
      expect(validateCustomerPhone('+62 812-345-678'), isNull);
    });
  });

  group('Customer mapper round-trip', () {
    test('fromMap memetakan field termasuk vehicle_count', () {
      final c = Customer.fromMap({
        'id': 'c1',
        'name': 'Budi Santoso',
        'phone': '0812',
        'address': 'Jl. Mawar',
        'note': 'VIP',
        'created_at': '2025-01-02T03:04:05.000Z',
        'vehicles': [
          {'count': 2}
        ],
      });
      expect(c.id, 'c1');
      expect(c.name, 'Budi Santoso');
      expect(c.phone, '0812');
      expect(c.address, 'Jl. Mawar');
      expect(c.note, 'VIP');
      expect(c.vehicleCount, 2);
      expect(c.vehicleCount, isA<int>());
      expect(c.createdAt, DateTime.parse('2025-01-02T03:04:05.000Z'));
    });

    test('fromMap tanpa vehicles -> vehicleCount 0', () {
      final c = Customer.fromMap({
        'id': 'c2',
        'name': 'Candra',
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(c.vehicleCount, 0);
      expect(c.phone, isNull);
    });

    test('toMap & copyWith', () {
      final c = Customer(
        id: 'c3',
        name: 'Dewi',
        phone: '0821',
        createdAt: DateTime.parse('2025-01-02T03:04:05.000Z'),
      );
      expect(c.toMap()['name'], 'Dewi');
      expect(c.copyWith(name: 'Dewi L').name, 'Dewi L');
    });
  });

  group('Vehicle mapper & plate normalization', () {
    test('fromMap normalisasi plat uppercase', () {
      final v = Vehicle.fromMap({
        'id': 'v1',
        'customer_id': 'c1',
        'plate_no': 'b 1234 abc',
        'brand': 'Toyota',
        'model': 'Avanza',
        'year': 2020,
        'created_at': '2025-01-02T03:04:05.000Z',
      });
      expect(v.plateNo, 'B 1234 ABC');
      expect(v.brand, 'Toyota');
      expect(v.year, 2020);
    });

    test('VehicleInput.toMap normalisasi plat & skip customer_id bila diminta', () {
      const input = VehicleInput(
        id: 'v1',
        customerId: 'c1',
        plateNo: 'b 9999 z',
        brand: '  ',
        model: 'X',
        year: 2019,
      );
      final withCust = input.toMap();
      final withoutCust = input.toMap(includeCustomerId: false);
      expect(withCust['plate_no'], 'B 9999 Z');
      expect(withCust['customer_id'], 'c1');
      expect(withoutCust.containsKey('customer_id'), isFalse);
      expect(withCust['brand'], isNull);
      expect(withCust['model'], 'X');
    });
  });
}
