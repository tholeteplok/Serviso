import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/theme/app_terms.dart';

void main() {
  group('AppTerms 2-Axis Separation', () {
    test('jasa + otomotif: servis murni bengkel tetap punya target kendaraan & odometer', () {
      final terms = AppTerms.forShop(businessType: 'jasa', serviceMode: 'otomotif');

      // Axis 1: serviceMode = otomotif
      expect(terms.targetLabel, 'Kendaraan');
      expect(terms.targetHint, 'Cari plat nomor...');
      expect(terms.complaintLabel, 'Keluhan');
      expect(terms.hasOdometer, isTrue);
      expect(terms.primaryPathIsVehicle, isTrue);
      expect(terms.alternatePathLinkLabel, '+ Servis tanpa kendaraan terdaftar');

      // Axis 2: businessType = jasa
      expect(terms.woListLabel, 'Antrian Pesanan');
      expect(terms.businessType, 'jasa');
    });

    test('jasa + umum: jasa laundry/AC/salon tanpa kendaraan & tanpa odometer', () {
      final terms = AppTerms.forShop(businessType: 'jasa', serviceMode: 'umum');

      // Axis 1: serviceMode = umum
      expect(terms.targetLabel, 'Objek / Layanan');
      expect(terms.complaintLabel, 'Instruksi / Catatan Layanan');
      expect(terms.hasOdometer, isFalse);
      expect(terms.primaryPathIsVehicle, isFalse);
      expect(terms.alternatePathLinkLabel, '+ Ada data kendaraan terdaftar?');

      // Axis 2: businessType = jasa
      expect(terms.woListLabel, 'Antrian Pesanan');
      expect(terms.businessType, 'jasa');
    });

    test('keduanya + otomotif: bengkel standar dengan penjualan sparepart', () {
      final terms = AppTerms.forShop(businessType: 'keduanya', serviceMode: 'otomotif');

      expect(terms.targetLabel, 'Kendaraan');
      expect(terms.hasOdometer, isTrue);
      expect(terms.primaryPathIsVehicle, isTrue);
      expect(terms.woListLabel, 'Antrian Servis');
      expect(terms.alternatePathLinkLabel, '+ Servis tanpa kendaraan terdaftar');
    });

    test('keduanya + umum: toko elektronik + perbaikan', () {
      final terms = AppTerms.forShop(businessType: 'keduanya', serviceMode: 'umum');

      expect(terms.targetLabel, 'Objek / Layanan');
      expect(terms.hasOdometer, isFalse);
      expect(terms.primaryPathIsVehicle, isFalse);
      expect(terms.woListLabel, 'Antrian Servis');
      expect(terms.alternatePathLinkLabel, '+ Ada data kendaraan terdaftar?');
    });

    test('barang (retail): alternatePathLinkLabel null', () {
      final terms = AppTerms.forShop(businessType: 'barang', serviceMode: 'otomotif');

      expect(terms.woListLabel, 'Pesanan');
      expect(terms.alternatePathLinkLabel, isNull);
    });

    test('backward-compatibility: forBusinessType redirects to forShop', () {
      final terms = AppTerms.forBusinessType('jasa', 'otomotif');
      expect(terms.businessType, 'jasa');
      expect(terms.serviceMode, 'otomotif');
      expect(terms.hasOdometer, isTrue);
    });
  });
}
