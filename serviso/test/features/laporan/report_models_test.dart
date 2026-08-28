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
}
