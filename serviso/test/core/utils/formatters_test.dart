import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/utils/formatters.dart';

void main() {
  group('rupiah', () {
    test('format id_ID tanpa spasi', () {
      expect(rupiah(1234567), 'Rp1.234.567');
    });

    test('nol', () {
      expect(rupiah(0), 'Rp0');
    });

    test('negatif memakai tanda minus di depan', () {
      expect(rupiah(-250000), '-Rp250.000');
    });

    test('desimal dibulatkan ke rupiah penuh', () {
      expect(rupiah(1500.75), 'Rp1.501');
    });
  });

  group('plate', () {
    test('uppercase dan trim', () {
      expect(plate(' b 1234 xyz '), 'B 1234 XYZ');
    });

    test('spasi ganda dirapikan', () {
      expect(plate('ab   9876  qrs'), 'AB 9876 QRS');
    });
  });

  group('dateTimeId dan timeId', () {
    test('tanggal waktu indonesia', () {
      final value = DateTime(2026, 8, 26, 14, 30);
      expect(dateTimeId(value), '26 Agu 2026, 14.30');
      expect(timeId(value), '14.30');
    });
  });
}
