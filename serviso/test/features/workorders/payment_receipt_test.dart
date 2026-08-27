import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/settings/data/settings_repository.dart';
import 'package:serviso/features/settings/models/app_settings.dart';
import 'package:serviso/features/workorders/data/fakes.dart';
import 'package:serviso/features/workorders/models/payment.dart';
import 'package:serviso/features/workorders/models/work_order.dart';
import 'package:serviso/features/workorders/pdf/receipt_builder.dart';

ReceiptInput buildSampleInput() {
  return ReceiptInput(
    shopName: 'Bengkel Serviso',
    shopAddress: 'Jl. Contoh No. 1',
    shopPhone: '08123456789',
    woNumber: 'WO-260101-001',
    plate: 'B 1234 ABC',
    vehicleDesc: 'Avanza 2018',
    customerName: 'Budi',
    items: const [
      WoItem(
        id: '1',
        kind: WoItemKind.jasa,
        description: 'Ganti oli',
        qty: 1,
        unitPrice: 100000,
        discount: 5000,
      ),
      WoItem(
        id: '2',
        kind: WoItemKind.part,
        partId: 'p1',
        partName: 'Busi',
        qty: 4,
        unitPrice: 25000,
      ),
    ],
    total: 190000,
    payMethod: 'Tunai',
    paidAmount: 200000,
    printedBy: 'Sari',
    printedAt: DateTime(2026, 1, 1, 10, 30),
  );
}

Future<String> makeSelesai(FakeWorkOrderRepository fake) async {
  final created = await fake.create(
    const WorkOrderDraft(
      vehicleId: 'v1',
      complaint: 'Service',
      items: [
        WoItemInput(
          kind: WoItemKind.jasa,
          description: 'Ganti oli',
          qty: 1,
          unitPrice: 100000,
        ),
      ],
    ),
  );
  await fake.start(created.id);
  await fake.complete(created.id);
  return created.id;
}

void main() {
  group('WoTotals.calculate', () {
    test('empty items -> semua nol', () {
      final totals = WoTotals.calculate(const []);
      expect(totals.subtotal, 0);
      expect(totals.totalDiscount, 0);
      expect(totals.total, 0);
    });

    test('subtotal, diskon per item, dan total', () {
      const items = [
        WoItem(
          id: '1',
          kind: WoItemKind.jasa,
          description: 'Ganti oli',
          qty: 1,
          unitPrice: 100000,
          discount: 10000,
        ),
        WoItem(
          id: '2',
          kind: WoItemKind.part,
          partId: 'p1',
          partName: 'Busi',
          qty: 4,
          unitPrice: 25000,
          discount: 0,
        ),
      ];
      final totals = WoTotals.calculate(items);
      expect(totals.subtotal, 200000);
      expect(totals.totalDiscount, 10000);
      expect(totals.total, 190000);
    });

    test('diskon melebihi subtotal tetap menghasilkan total', () {
      const items = [
        WoItem(
          id: '1',
          kind: WoItemKind.jasa,
          description: 'Jasa',
          qty: 1,
          unitPrice: 50000,
          discount: 80000,
        ),
      ];
      final totals = WoTotals.calculate(items);
      expect(totals.subtotal, 50000);
      expect(totals.totalDiscount, 80000);
      expect(totals.total, -30000);
    });
  });

  group('validatePaymentAmount', () {
    test('menolak nilai negatif', () {
      final result = validatePaymentAmount(-1000, 50000);
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('menolak NaN/infinite', () {
      expect(validatePaymentAmount(double.nan, 50000).isValid, isFalse);
      expect(validatePaymentAmount(double.infinity, 50000).isValid, isFalse);
    });

    test('menerima nominal sama dengan total', () {
      final result = validatePaymentAmount(50000, 50000);
      expect(result.isValid, isTrue);
    });

    test('menerima pembayaran lebih (kembalian)', () {
      final result = validatePaymentAmount(60000, 50000);
      expect(result.isValid, isTrue);
    });
  });

  group('PaymentMethod label', () {
    test('setiap metode punya label Indonesia', () {
      expect(PaymentMethod.cash.label, 'Tunai');
      expect(PaymentMethod.transfer.label, 'Transfer');
      expect(PaymentMethod.qris.label, 'QRIS');
    });

    test('fromValue memetakan string ke enum', () {
      expect(PaymentMethodX.fromValue('cash'), PaymentMethod.cash);
      expect(PaymentMethodX.fromValue('transfer'), PaymentMethod.transfer);
      expect(PaymentMethodX.fromValue('qris'), PaymentMethod.qris);
      expect(PaymentMethodX.fromValue(null), PaymentMethod.cash);
    });
  });

  group('buildReceiptPdf', () {
    test('menghasilkan bytes tidak kosong', () async {
      final result = await buildReceiptPdf(buildSampleInput());
      expect(result.bytes, isNotEmpty);
      expect(result.filename, 'struk_WO-260101-001.pdf');
    });

    test('dokumen memiliki tepat 1 halaman', () async {
      final result = await buildReceiptPdf(buildSampleInput());
      expect(result.pageCount, 1);
    });
  });

  group('kembalian hanya untuk Tunai', () {
    test('overpay Tunai -> tampil', () {
      expect(shouldShowChange('Tunai', 200000, 190000), isTrue);
    });

    test('overpay Transfer/QRIS -> tidak tampil', () {
      expect(shouldShowChange('Transfer', 200000, 190000), isFalse);
      expect(shouldShowChange('QRIS', 200000, 190000), isFalse);
    });

    test('pas/ kurang -> tidak tampil untuk semua metode', () {
      expect(shouldShowChange('Tunai', 190000, 190000), isFalse);
      expect(shouldShowChange('Tunai', 100000, 190000), isFalse);
      expect(shouldShowChange('Transfer', 100000, 190000), isFalse);
    });
  });

  group('footer struk', () {
    test('mengandung · dan tidak mengandung -+', () {
      final footer = buildReceiptFooter('Sari', DateTime(2026, 1, 1, 10, 30));
      expect(footer.contains('·'), isTrue);
      expect(footer.contains('-+'), isFalse);
    });

    test('footer menyertakan nama pencetak', () {
      final footer = buildReceiptFooter('Budi', DateTime(2026, 1, 1, 10, 30));
      expect(footer, contains('Dicetak oleh Budi'));
    });
  });

  group('FakeSettingsRepository admin gate', () {
    test('update berhasil untuk admin', () async {
      final repo = FakeSettingsRepository(allowAdmin: true);
      final updated = await repo.updateSettings(
        shopName: 'Serviso Cabang',
        address: 'Jl. Baru',
        phone: '08000',
      );
      expect(updated.shopName, 'Serviso Cabang');
      expect(repo.current.shopName, 'Serviso Cabang');
    });

    test('update ditolak untuk non-admin', () async {
      final repo = FakeSettingsRepository(allowAdmin: false);
      expect(
        () => repo.updateSettings(shopName: 'X'),
        throwsA(isA<SettingsException>()),
      );
    });

    test('getSettings mengembalikan default', () async {
      final repo = FakeSettingsRepository();
      final settings = await repo.getSettings();
      expect(settings, isA<AppSettings>());
      expect(settings.shopName, 'Bengkel Serviso');
    });
  });

  group('FakeWorkOrderRepository pay', () {
    test('pay mencatat paid_at dan metode', () async {
      final fake = FakeWorkOrderRepository();
      final id = await makeSelesai(fake);
      await fake.pay(
        id: id,
        paidAmount: 100000,
        payMethod: PaymentMethod.cash,
      );
      final order = await fake.getById(id);
      expect(order!.isPaid, isTrue);
      expect(order.paidAt, isNotNull);
      expect(order.payMethod, PaymentMethod.cash);
      expect(order.paidAmount, 100000);
    });
  });
}
