import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/models/wo_status.dart';
import 'package:serviso/features/workorders/models/work_order.dart';
import 'package:serviso/features/workorders/pdf/spk_actions.dart';
import 'package:serviso/features/workorders/pdf/spk_builder.dart';

void main() {
  group('SPK Builder & Actions Tests', () {
    test('buildSpkPdf menghasilkan dokumen PDF A5 yang valid dengan bytes tidak kosong', () async {
      final input = SpkInput(
        shopName: 'Bengkel Serviso Berkah',
        shopAddress: 'Jl. Merdeka No. 45',
        shopPhone: '081234567890',
        spkNumber: 'WO-260906-001',
        createdAt: DateTime(2026, 9, 6, 8, 30),
        customerName: 'Ahmad Fauzi',
        customerPhone: '08987654321',
        targetLabel: 'Kendaraan',
        targetValue: 'B 1234 XYZ - Toyota Avanza 2020',
        complaintLabel: 'Keluhan Pelanggan',
        complaint: 'Rem bunyi mendecit dan tarikan gas agak berat saat tanjakan',
        technicianName: 'Siti Aminah',
        items: const [
          WoItem(
            id: '1',
            kind: WoItemKind.jasa,
            description: 'Servis Rem 4 Roda',
            qty: 1,
            unitPrice: 150000,
          ),
          WoItem(
            id: '2',
            kind: WoItemKind.part,
            partName: 'Kampas Rem Depan',
            qty: 1,
            unitPrice: 220000,
          ),
        ],
        printedBy: 'Kasir Utama',
        printedAt: DateTime(2026, 9, 6, 8, 35),
      );

      final result = await buildSpkPdf(input);
      expect(result.bytes.isNotEmpty, isTrue);
      expect(result.filename, 'SPK-WO-260906-001.pdf');
    });

    test('buildSpkInputFromWorkOrder memetakan target kendaraan dan jasa non-otomotif dengan benar', () {
      final woKendaraan = WorkOrder(
        id: 'wo-1',
        woNumber: 'WO-260906-001',
        status: WoStatus.menunggu,
        vehicleId: 'v-1',
        plateNo: 'B 9999 DEF',
        vehicleDesc: 'Honda Vario 160',
        customerName: 'Bambang',
        assignedName: 'Doni',
        complaint: 'Ganti oli mesin dan gardan',
        createdAt: DateTime(2026, 9, 6, 9, 0),
      );

      final input1 = buildSpkInputFromWorkOrder(
        order: woKendaraan,
        shopName: 'Toko Servis',
        targetLabel: 'Kendaraan',
        complaintLabel: 'Keluhan',
        technicianName: woKendaraan.assignedName,
        printedBy: 'Admin',
      );

      expect(input1.targetValue, 'B 9999 DEF - Honda Vario 160');
      expect(input1.customerName, 'Bambang');
      expect(input1.technicianName, 'Doni');

      final woManual = WorkOrder(
        id: 'wo-2',
        woNumber: 'WO-260906-002',
        status: WoStatus.menunggu,
        serviceLabel: 'Laptop Asus ROG Strix G15',
        customerName: 'Cindy',
        complaint: 'Kipas bunyi berisik dan overheat',
        createdAt: DateTime(2026, 9, 6, 9, 15),
      );

      final input2 = buildSpkInputFromWorkOrder(
        order: woManual,
        shopName: 'Servis Komputer',
        customerPhone: '0811223344',
        targetLabel: 'Objek Servis',
        complaintLabel: 'Deskripsi Masalah',
        printedBy: 'Admin',
      );

      expect(input2.targetValue, 'Laptop Asus ROG Strix G15');
      expect(input2.customerPhone, '0811223344');
      expect(input2.technicianName, isNull);
    });
  });
}
