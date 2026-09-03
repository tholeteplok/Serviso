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

  DirectSaleItemInput copyWith({
    WoItemKind? kind,
    String? partId,
    String? description,
    double? qty,
    double? unitPrice,
    double? discount,
  }) =>
      DirectSaleItemInput(
        kind: kind ?? this.kind,
        partId: partId ?? this.partId,
        description: description ?? this.description,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        discount: discount ?? this.discount,
      );

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

class DirectSaleResult {
  const DirectSaleResult({
    required this.id,
    required this.saleNumber,
  });

  final String id;
  final String saleNumber;

  factory DirectSaleResult.fromMap(Map<String, dynamic> map) {
    return DirectSaleResult(
      id: map['id'] as String? ?? '',
      saleNumber: map['sale_number'] as String? ?? (map['id'] as String? ?? ''),
    );
  }
}
