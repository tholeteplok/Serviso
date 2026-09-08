import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serviso/features/direct_sales/data/hold_transaction_service.dart';
import 'package:serviso/features/direct_sales/models/direct_sale.dart';
import 'package:serviso/features/workorders/models/payment.dart';
import 'package:serviso/features/workorders/models/work_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HoldSaleDraft Model & Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('HoldSaleDraft toMap and fromMap roundtrip correctly', () {
      final now = DateTime.now();
      final draft = HoldSaleDraft(
        id: 'draft-1',
        note: 'Budi Santoso',
        customerId: 'cust-10',
        customerName: 'Budi Santoso',
        createdAt: now,
        items: const [
          DirectSaleItemInput(
            kind: WoItemKind.part,
            partId: 'p1',
            description: 'Oli MPX 1',
            qty: 2,
            unitPrice: 55000,
            discount: 5000,
          ),
          DirectSaleItemInput(
            kind: WoItemKind.jasa,
            description: 'Jasa Pasang',
            qty: 1,
            unitPrice: 15000,
          ),
        ],
        payMethod: PaymentMethod.qris,
        paidAmount: 0.0,
      );

      expect(draft.total, 120000.0); // (2 * 55000 - 5000) + (1 * 15000)

      final map = draft.toMap();
      final deserialized = HoldSaleDraft.fromMap(map);

      expect(deserialized.id, 'draft-1');
      expect(deserialized.customerName, 'Budi Santoso');
      expect(deserialized.items.length, 2);
      expect(deserialized.items.first.description, 'Oli MPX 1');
      expect(deserialized.items.first.qty, 2);
      expect(deserialized.items.first.unitPrice, 55000);
      expect(deserialized.payMethod, PaymentMethod.qris);
      expect(deserialized.total, 120000.0);
    });

    test('HoldTransactionNotifier saves, loads, and deletes drafts', () async {
      final notifier = HoldTransactionNotifier();
      await notifier.loadDrafts();
      expect(notifier.state, isEmpty);

      final draft1 = HoldSaleDraft(
        id: 'draft-101',
        customerName: 'Pelanggan A',
        createdAt: DateTime.now(),
        items: const [
          DirectSaleItemInput(
            kind: WoItemKind.part,
            description: 'Busi NGK',
            qty: 1,
            unitPrice: 20000,
          ),
        ],
      );

      final draft2 = HoldSaleDraft(
        id: 'draft-102',
        customerName: 'Pelanggan B',
        createdAt: DateTime.now(),
        items: const [
          DirectSaleItemInput(
            kind: WoItemKind.part,
            description: 'Filter Udara',
            qty: 1,
            unitPrice: 35000,
          ),
        ],
      );

      await notifier.saveDraft(draft1);
      await notifier.saveDraft(draft2);
      expect(notifier.state.length, 2);
      expect(notifier.state.any((d) => d.id == 'draft-101'), isTrue);
      expect(notifier.state.any((d) => d.id == 'draft-102'), isTrue);

      // Delete draft 101
      await notifier.deleteDraft('draft-101');
      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, 'draft-102');

      // Clear all
      await notifier.clearAll();
      expect(notifier.state, isEmpty);
    });
  });
}
