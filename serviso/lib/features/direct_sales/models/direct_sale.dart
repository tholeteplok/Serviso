import '../../workorders/models/payment.dart';
import '../../workorders/models/work_order.dart';

class DirectSaleItemInput {
  const DirectSaleItemInput({
    required this.kind,
    this.partId,
    this.description,
    required this.qty,
    required this.unitPrice,
    this.discount = 0,
  });

  final WoItemKind kind;
  final String? partId;
  final String? description;
  final double qty;
  final double unitPrice;
  final double discount;

  double get lineTotal {
    final raw = qty * unitPrice - discount;
    return raw < 0 ? 0 : raw;
  }

  Map<String, dynamic> toJson() => {
        'kind': kind == WoItemKind.part ? 'part' : 'jasa',
        'part_id': partId,
        'description': description,
        'qty': qty,
        'unit_price': unitPrice,
        'discount': discount,
      };
}

class DirectSaleDraft {
  const DirectSaleDraft({
    this.customerId,
    required this.items,
    required this.payMethod,
    required this.paidAmount,
  });

  final String? customerId;
  final List<DirectSaleItemInput> items;
  final PaymentMethod payMethod;
  final double paidAmount;

  double get total => items.fold(0.0, (s, e) => s + e.lineTotal);
}
