import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/models/wo_status.dart';
import 'package:serviso/features/customers/models/customer.dart';
import 'package:serviso/features/customers/models/vehicle.dart';
import 'package:serviso/features/workorders/data/fakes.dart';
import 'package:serviso/features/workorders/models/payment.dart';
import 'package:serviso/features/workorders/models/work_order.dart';
import 'package:serviso/features/workorders/pdf/receipt_builder.dart';

void main() {
  group('Alur Operasional Transaksi Bengkel (End-to-End)', () {
    late FakeWorkOrderRepository woRepo;

    setUp(() {
      woRepo = FakeWorkOrderRepository();
    });

    test('Skenario Lengkap: Registrasi -> WO -> Servis -> Potong Stok -> Pembayaran -> Cetak Struk', () async {
      // -------------------------------------------------------------
      // 1. DATA MASTER: Pelanggan & Kendaraan Masuk
      // -------------------------------------------------------------
      final now = DateTime.now();
      final customer = Customer(
        id: 'cust-001',
        name: 'Pak Budi Hartono',
        phone: '081234567890',
        vehicleCount: 1,
        createdAt: now,
      );

      final vehicle = Vehicle(
        id: 'veh-001',
        customerId: customer.id,
        plateNo: 'B 1234 SVO',
        brand: 'Honda',
        model: 'Vario 160',
        year: 2023,
        createdAt: now,
      );

      expect(vehicle.customerId, customer.id);
      expect(vehicle.plateNo, 'B 1234 SVO');

      // -------------------------------------------------------------
      // 2. INVENTORI: Siapkan Stok Awal Suku Cadang (10 unit)
      // -------------------------------------------------------------
      const partId = 'part-oli-01';
      woRepo.seedPartStock(partId, 10.0);

      // -------------------------------------------------------------
      // 3. PENDAFTARAN WO: Kasir Membuat Work Order Baru
      //    - Keluhan: "Ganti oli dan servis rem"
      //    - Jasa: "Jasa Stel & Bersih Rem" @ Rp 25.000
      //    - Part: 2 Botol Oli @ Rp 55.000 (Harga disesuaikan oleh kasir)
      // -------------------------------------------------------------
      final draft = WorkOrderDraft(
        vehicleId: vehicle.id,
        complaint: 'Ganti oli dan servis rem',
        odometerIn: 15400,
        items: const [
          WoItemInput(
            kind: WoItemKind.jasa,
            description: 'Jasa Stel & Bersih Rem',
            qty: 1,
            unitPrice: 25000,
          ),
          WoItemInput(
            kind: WoItemKind.part,
            partId: partId,
            partName: 'Oli Mesin Matic 0.8L',
            description: 'Oli Mesin Matic 0.8L',
            qty: 2,
            unitPrice: 55000,
          ),
        ],
      );

      final createdWo = await woRepo.create(draft);

      // Verifikasi status awal
      expect(createdWo.status, WoStatus.menunggu);
      expect(createdWo.woNumber.startsWith('WO-'), isTrue);
      expect(createdWo.items.length, 2);
      expect(createdWo.total, 135000); // 25.000 + (2 * 55.000)

      // -------------------------------------------------------------
      // 4. PENGERJAAN: Mekanik Mulai Kerja & Menambah Jasa Tambahan
      // -------------------------------------------------------------
      await woRepo.start(createdWo.id);

      final inProgressWo = await woRepo.getById(createdWo.id);
      expect(inProgressWo!.status, WoStatus.dikerjakan);

      // Mekanik menemukan filter udara kotor, menambah jasa pembersihan
      await woRepo.addItem(
        createdWo.id,
        const WoItemInput(
          kind: WoItemKind.jasa,
          description: 'Pembersihan Filter Udara & Throttle Body',
          qty: 1,
          unitPrice: 30000,
        ),
      );

      final updatedWo = await woRepo.getById(createdWo.id);
      expect(updatedWo!.items.length, 3);
      expect(updatedWo.total, 165000); // 135.000 + 30.000

      // -------------------------------------------------------------
      // 5. PENYELESAIAN SERVIS: Otomatis Potong Stok Inventori
      // -------------------------------------------------------------
      await woRepo.complete(createdWo.id);

      final completedWo = await woRepo.getById(createdWo.id);
      expect(completedWo!.status, WoStatus.selesai);
      expect(completedWo.completedAt, isNotNull);

      // Verifikasi ledger dan pengurangan stok
      final ledgerEntries = woRepo.ledger.where((l) => l.partId == partId).toList();
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.direction, 'out');
      expect(ledgerEntries.first.refType, 'wo');
      expect(ledgerEntries.first.qty, 2.0);

      // -------------------------------------------------------------
      // 6. KASIR & PEMBAYARAN: Pembayaran Tunai & Hitung Kembalian
      // -------------------------------------------------------------
      const bayarNominal = 200000.0;
      final totalTagihan = completedWo.total;
      expect(totalTagihan, 165000.0);

      final kembalian = bayarNominal - totalTagihan;
      expect(kembalian, 35000.0);

      await woRepo.pay(
        id: completedWo.id,
        paidAmount: bayarNominal,
        payMethod: PaymentMethod.cash,
      );

      final paidWo = await woRepo.getById(completedWo.id);
      expect(paidWo!.paidAmount, bayarNominal);
      expect(paidWo.payMethod, PaymentMethod.cash);
      expect(paidWo.paidAt, isNotNull);
      expect(paidWo.isPaid, isTrue);
      expect(paidWo.paymentStatusLabel, 'Lunas');

      // -------------------------------------------------------------
      // 7. CETAK STRUK: Generate PDF Struk Transaksi Resmi
      // -------------------------------------------------------------
      final receiptInput = ReceiptInput(
        shopName: 'Bengkel Serviso Utama',
        shopAddress: 'Jl. Ahmad Yani No. 88, Surabaya',
        shopPhone: '081122334455',
        woNumber: paidWo.woNumber,
        plate: vehicle.plateNo,
        vehicleDesc: '${vehicle.brand} ${vehicle.model} (${vehicle.year})',
        customerName: customer.name,
        items: paidWo.items,
        total: totalTagihan,
        payMethod: 'Tunai',
        paidAmount: bayarNominal,
        printedBy: 'Kasir 1',
        printedAt: DateTime.now(),
      );

      final receiptResult = await buildReceiptPdf(receiptInput);

      // Validasi PDF Struk
      expect(receiptResult.bytes, isNotEmpty);
      expect(receiptResult.bytes.length, greaterThan(1000));
      expect(receiptResult.pageCount, 1);
      expect(receiptResult.filename.contains(paidWo.woNumber), isTrue);
    });

    test('Skenario Pembatalan & Pembalikan Stok (Reversal Path)', () async {
      // Siapkan stok 5 unit
      const partId = 'part-kampas-01';
      woRepo.seedPartStock(partId, 5.0);

      final created = await woRepo.create(
        const WorkOrderDraft(
          vehicleId: 'veh-002',
          complaint: 'Ganti kampas rem',
          items: [
            WoItemInput(
              kind: WoItemKind.part,
              partId: partId,
              partName: 'Kampas Rem Depan',
              qty: 2,
              unitPrice: 75000,
            ),
          ],
        ),
      );

      // Selesaikan servis -> Stok terpotong 2
      await woRepo.start(created.id);
      await woRepo.complete(created.id);

      final finishedWo = await woRepo.getById(created.id);
      expect(finishedWo!.status, WoStatus.selesai);

      // Admin membatalkan WO karena ada kesalahan -> Stok harus dibalikkan (reversal)
      await woRepo.cancel(created.id);

      final cancelledWo = await woRepo.getById(created.id);
      expect(cancelledWo!.status, WoStatus.dibatalkan);

      // Verifikasi ledger reversal
      final reversalEntries = woRepo.ledger
          .where((l) => l.partId == partId && l.refType == 'pembatalan')
          .toList();

      expect(reversalEntries.length, 1);
      expect(reversalEntries.first.direction, 'in');
      expect(reversalEntries.first.qty, 2.0);
    });
  });
}
