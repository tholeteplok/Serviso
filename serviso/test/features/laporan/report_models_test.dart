import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/features/laporan/models/report_models.dart';

void main() {
  group('DailySummaryRow', () {
    test('fromMap & toMap conversion', () {
      final map = {
        'date': '2026-08-28',
        'revenue': 1500000.0,
        'wo_done_count': 5,
        'parts_out_qty': 12.5,
      };

      final row = DailySummaryRow.fromMap(map);
      expect(row.revenue, 1500000.0);
      expect(row.woDoneCount, 5);
      expect(row.partsOutQty, 12.5);

      final exported = row.toMap();
      expect(exported['date'], '2026-08-28');
      expect(exported['revenue'], 1500000.0);
    });
  });

  group('TopPartRow', () {
    test('fromMap & toMap conversion', () {
      final map = {
        'month_start': '2026-08-01',
        'part_id': 'part-123',
        'name': 'Oli Mesin 1L',
        'qty_out': 20.0,
        'revenue': 2000000.0,
      };

      final row = TopPartRow.fromMap(map);
      expect(row.partId, 'part-123');
      expect(row.name, 'Oli Mesin 1L');
      expect(row.qtyOut, 20.0);

      final exported = row.toMap();
      expect(exported['month_start'], '2026-08-01');
      expect(exported['name'], 'Oli Mesin 1L');
    });
  });

  group('WoDoneRow', () {
    test('fromMap parses vehicleDesc from brand and model & handles fallback customer', () {
      final map = {
        'id': 'wo-1',
        'wo_number': 'WO-2026-001',
        'vehicles': {
          'plate_no': 'B 1234 XYZ',
          'brand': 'Honda',
          'model': 'Vario 150',
          'customers': {
            'name': 'Budi Santoso',
          },
        },
        'wo_items': [{'id': 'item-1'}, {'id': 'item-2'}],
        'completed_at': '2026-09-08T10:00:00Z',
        'paid_amount': 250000.0,
        'status': 'selesai',
        'pay_method': 'cash',
      };

      final row = WoDoneRow.fromMap(map);
      expect(row.id, 'wo-1');
      expect(row.woNumber, 'WO-2026-001');
      expect(row.plateNo, 'B 1234 XYZ');
      expect(row.vehicleDesc, 'Honda Vario 150');
      expect(row.customerName, 'Budi Santoso');
      expect(row.itemCount, 2);
      expect(row.paidAmount, 250000.0);
      expect(row.payMethod, 'cash');

      final exported = row.toMap();
      expect(exported['vehicle_desc'], 'Honda Vario 150');
      expect(exported['customer_name'], 'Budi Santoso');
    });

    test('fromMap falls back to direct customer_name if vehicle customer is absent', () {
      final map = {
        'id': 'wo-2',
        'wo_number': 'WO-2026-002',
        'customer_name': 'Pelanggan Walk-In',
        'vehicles': {
          'plate_no': 'D 9999 ABC',
        },
        'completed_at': '2026-09-08T11:00:00Z',
        'paid_amount': 75000.0,
        'status': 'selesai',
        'pay_method': 'qris',
      };

      final row = WoDoneRow.fromMap(map);
      expect(row.customerName, 'Pelanggan Walk-In');
      expect(row.plateNo, 'D 9999 ABC');
      expect(row.vehicleDesc, isNull);
      expect(row.itemCount, 0);
    });
  });
}
