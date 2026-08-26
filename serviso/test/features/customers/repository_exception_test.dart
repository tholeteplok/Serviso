import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:serviso/features/customers/data/fakes.dart';
import 'package:serviso/features/customers/data/repository_exception.dart';
import 'package:serviso/features/customers/models/vehicle.dart';

void main() {
  group('mapRepositoryError', () {
    test('PostgrestException duplikat plate_no -> pesan plat terdaftar', () {
      const e = PostgrestException(
        message:
            'duplicate key value violates unique constraint "vehicles_plate_no_key"',
        code: '23505',
      );
      expect(mapRepositoryError(e), 'Plat nomor sudah terdaftar');
    });

    test('message mengandung plate_no tanpa code -> pesan plat terdaftar', () {
      const e = PostgrestException(
        message: 'Key (plate_no)=(B 1234 ABC) already exists.',
        code: 'XXXXX',
      );
      expect(mapRepositoryError(e), 'Plat nomor sudah terdaftar');
    });

    test('FK restrict hapus pelanggan ber-kendaraan -> pesan dengan kendaraan', () {
      const e = PostgrestException(
        message:
            'update or delete on table "customers" violates foreign key constraint "vehicles_customer_id_fkey"',
        code: '23503',
      );
      expect(
        mapRepositoryError(e),
        'Hapus dulu kendaraan milik pelanggan ini',
      );
    });

    test('RepositoryException dilewatkan apa adanya', () {
      const e = RepositoryException('Pesan kustom');
      expect(mapRepositoryError(e), 'Pesan kustom');
    });

    test('error tak dikenal -> pesan generik', () {
      expect(mapRepositoryError(Exception('boom')), contains('Gagal memproses'));
    });
  });

  group('Fake repository duplicate plate', () {
    test('create kendaraan melempar pesan plat terdaftar', () async {
      final fake = FakeVehicleRepository(throwDuplicatePlate: true);
      expect(
        () => fake.create(
          const VehicleInput(customerId: 'c1', plateNo: 'B 1'),
        ),
        throwsA(
          isA<RepositoryException>().having(
            (e) => e.message,
            'message',
            'Plat nomor sudah terdaftar',
          ),
        ),
      );
    });

    test('delete pelanggan dengan kendaraan (restrict) melempar pesan', () async {
      final fake = FakeCustomerRepository(throwRestrictOnDelete: true);
      expect(
        () => fake.delete('c1'),
        throwsA(
          isA<RepositoryException>().having(
            (e) => e.message,
            'message',
            'Hapus dulu kendaraan milik pelanggan ini',
          ),
        ),
      );
    });
  });
}
