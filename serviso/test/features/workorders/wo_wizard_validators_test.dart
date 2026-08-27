import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/workorders/logic/wo_validators.dart';
import 'package:serviso/features/workorders/models/work_order.dart';

void main() {
  group('WoValidators', () {
    test('complaint wajib diisi', () {
      expect(WoValidators.validateComplaint(null), isNotNull);
      expect(WoValidators.validateComplaint(''), isNotNull);
      expect(WoValidators.validateComplaint('   '), isNotNull);
      expect(WoValidators.validateComplaint('Mesin overheat'), isNull);
    });

    test('qty part harus > 0', () {
      expect(WoValidators.validatePartQty(0), isNotNull);
      expect(WoValidators.validatePartQty(-1), isNotNull);
      expect(WoValidators.validatePartQty(2), isNull);
    });

    test('harga jasa harus > 0', () {
      expect(WoValidators.validateJasaPrice(0), isNotNull);
      expect(WoValidators.validateJasaPrice(50000), isNull);
    });

    test('isValidDraft menolak keluhan kosong dan qty <= 0', () {
      const ok = WorkOrderDraft(
        vehicleId: 'v1',
        complaint: 'Service',
        items: [
          WoItemInput(kind: WoItemKind.part, partId: 'p1', qty: 2, unitPrice: 1000),
        ],
      );
      const noComplaint = WorkOrderDraft(
        vehicleId: 'v1',
        complaint: '',
        items: [],
      );
      const badQty = WorkOrderDraft(
        vehicleId: 'v1',
        complaint: 'Service',
        items: [
          WoItemInput(kind: WoItemKind.part, partId: 'p1', qty: 0, unitPrice: 1000),
        ],
      );
      expect(WoValidators.isValidDraft(ok), isTrue);
      expect(WoValidators.isValidDraft(noComplaint), isFalse);
      expect(WoValidators.isValidDraft(badQty), isFalse);
    });
  });
}
