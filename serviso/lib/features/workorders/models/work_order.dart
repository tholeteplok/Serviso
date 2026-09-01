import '../../../core/models/wo_status.dart';
import 'payment.dart';

double _parseNumeric(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

enum WoItemKind { part, jasa }

class WoItem {
  const WoItem({
    required this.id,
    required this.kind,
    this.partId,
    this.partName,
    this.description,
    required this.qty,
    required this.unitPrice,
    this.discount = 0,
  });

  final String id;
  final WoItemKind kind;
  final String? partId;
  final String? partName;
  final String? description;
  final double qty;
  final double unitPrice;
  final double discount;

  factory WoItem.fromMap(Map<String, dynamic> map) {
    final parts = map['parts'];
    final partName = parts is Map
        ? ((parts['name'] as String?)?.isNotEmpty == true
            ? parts['name'] as String
            : parts['code'] as String?)
        : null;
    final qty = _parseNumeric(map['qty']);
    final unitPrice = _parseNumeric(map['unit_price']);
    var discount = _parseNumeric(map['discount']);
    // Clamp discount agar tidak melebihi subtotal (DB juga enforce)
    final maxDiscount = qty * unitPrice;
    if (discount > maxDiscount) discount = maxDiscount;
    if (discount < 0) discount = 0;
    return WoItem(
      id: map['id'] as String,
      kind: map['kind'] == 'part' ? WoItemKind.part : WoItemKind.jasa,
      partId: map['part_id'] as String?,
      partName: partName,
      description: map['description'] as String?,
      qty: qty,
      unitPrice: unitPrice,
      discount: discount,
    );
  }

  double get lineTotal {
    final raw = (qty * unitPrice) - discount;
    return raw < 0 ? 0 : raw;
  }

  Map<String, dynamic> toInsertMap(String workOrderId) => {
        'work_order_id': workOrderId,
        'kind': kind == WoItemKind.part ? 'part' : 'jasa',
        'part_id': partId,
        'description': description?.trim().isEmpty == true ? null : description?.trim(),
        'qty': qty,
        'unit_price': unitPrice,
        'discount': discount,
      };
}

class WorkOrder {
  const WorkOrder({
    required this.id,
    required this.woNumber,
    required this.status,
    required this.vehicleId,
    this.plateNo,
    this.vehicleDesc,
    this.customerName,
    this.assignedName,
    this.assignedTo,
    this.complaint,
    this.diagnosis,
    this.techNote,
    this.odometerIn,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.paidAmount = 0,
    this.payMethod,
    this.paidAt,
    this.items = const [],
  });

  final String id;
  final String woNumber;
  final WoStatus status;
  final String vehicleId;
  final String? plateNo;
  final String? vehicleDesc;
  final String? customerName;
  final String? assignedName;
  final String? assignedTo;
  final String? complaint;
  final String? diagnosis;
  final String? techNote;
  final int? odometerIn;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double paidAmount;
  final PaymentMethod? payMethod;
  final DateTime? paidAt;
  final List<WoItem> items;

  bool get isPaid => paidAt != null;

  String get paymentStatusLabel => isPaid ? 'Lunas' : 'Belum Lunas';

  double get total => items.fold(0.0, (sum, i) => sum + i.lineTotal);

  factory WorkOrder.fromBoardMap(Map<String, dynamic> map) {
    final vehicles = map['vehicles'];
    String? plateNo;
    String? vehicleDesc;
    String? customerName;
    if (vehicles is Map) {
      plateNo = vehicles['plate_no'] as String?;
      final brand = vehicles['brand'] as String?;
      final model = vehicles['model'] as String?;
      vehicleDesc = [brand, model].where((e) => e != null && e.isNotEmpty).join(' ');
      final cust = vehicles['customers'];
      if (cust is Map) customerName = cust['name'] as String?;
    }
    final assignee = map['assignee'];
    final assignedName = assignee is Map ? assignee['full_name'] as String? : null;

    return WorkOrder(
      id: map['id'] as String,
      woNumber: (map['wo_number'] as String?) ?? '',
      status: _statusFromString(map['status'] as String?),
      vehicleId: map['vehicle_id'] as String,
      plateNo: plateNo,
      vehicleDesc: vehicleDesc?.isNotEmpty == true ? vehicleDesc : null,
      customerName: customerName,
      assignedName: assignedName,
      assignedTo: map['assigned_to'] as String?,
      complaint: map['complaint'] as String?,
      diagnosis: map['diagnosis'] as String?,
      techNote: map['tech_note'] as String?,
      odometerIn: map['odometer_in'] as int?,
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] == null
          ? null
          : DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      paidAmount: _parseNumeric(map['paid_amount']),
      payMethod: PaymentMethodX.fromValue(map['pay_method'] as String?),
      paidAt: map['paid_at'] == null
          ? null
          : DateTime.parse(map['paid_at'] as String),
    );
  }

  factory WorkOrder.fromDetailMap(Map<String, dynamic> map) {
    final base = WorkOrder.fromBoardMap(map);
    final itemsRaw = map['wo_items'];
    List<WoItem> items = const [];
    if (itemsRaw is List) {
      items = itemsRaw
          .map((m) => WoItem.fromMap(m as Map<String, dynamic>))
          .toList();
    }
    return base.copyWith(items: items);
  }

  WorkOrder copyWith({
    String? id,
    String? woNumber,
    WoStatus? status,
    String? vehicleId,
    String? plateNo,
    String? vehicleDesc,
    String? customerName,
    String? assignedName,
    String? assignedTo,
    String? complaint,
    String? diagnosis,
    String? techNote,
    int? odometerIn,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? paidAmount,
    PaymentMethod? payMethod,
    DateTime? paidAt,
    List<WoItem>? items,
  }) =>
      WorkOrder(
        id: id ?? this.id,
        woNumber: woNumber ?? this.woNumber,
        status: status ?? this.status,
        vehicleId: vehicleId ?? this.vehicleId,
        plateNo: plateNo ?? this.plateNo,
        vehicleDesc: vehicleDesc ?? this.vehicleDesc,
        customerName: customerName ?? this.customerName,
        assignedName: assignedName ?? this.assignedName,
        assignedTo: assignedTo ?? this.assignedTo,
        complaint: complaint ?? this.complaint,
        diagnosis: diagnosis ?? this.diagnosis,
        techNote: techNote ?? this.techNote,
        odometerIn: odometerIn ?? this.odometerIn,
        createdAt: createdAt ?? this.createdAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        paidAmount: paidAmount ?? this.paidAmount,
        payMethod: payMethod ?? this.payMethod,
        paidAt: paidAt ?? this.paidAt,
        items: items ?? this.items,
      );

  Map<String, dynamic> toInsertMap() => {
        'vehicle_id': vehicleId,
        'assigned_to': assignedTo,
        'complaint': complaint?.trim().isEmpty == true ? null : complaint?.trim(),
        'odometer_in': odometerIn,
      };
}

class WoItemInput {
  const WoItemInput({
    required this.kind,
    this.partId,
    this.partName,
    this.description,
    required this.qty,
    required this.unitPrice,
    this.discount = 0,
  });

  final WoItemKind kind;
  final String? partId;
  final String? partName;
  final String? description;
  final double qty;
  final double unitPrice;
  final double discount;

  Map<String, dynamic> toInsertMap(String workOrderId) => {
        'work_order_id': workOrderId,
        'kind': kind == WoItemKind.part ? 'part' : 'jasa',
        'part_id': partId,
        'description':
            description?.trim().isEmpty == true ? null : description?.trim(),
        'qty': qty,
        'unit_price': unitPrice,
        'discount': discount,
      };
}

class WorkOrderDraft {
  const WorkOrderDraft({
    required this.vehicleId,
    this.assignedTo,
    this.complaint,
    this.odometerIn,
    required this.items,
  });

  final String vehicleId;
  final String? assignedTo;
  final String? complaint;
  final int? odometerIn;
  final List<WoItemInput> items;

  Map<String, dynamic> toInsertMap() => {
        'vehicle_id': vehicleId,
        'assigned_to': assignedTo,
        'complaint':
            complaint?.trim().isEmpty == true ? null : complaint?.trim(),
        'odometer_in': odometerIn,
      };
}

WoStatus _statusFromString(String? value) {
  switch (value) {
    case 'menunggu':
      return WoStatus.menunggu;
    case 'dikerjakan':
      return WoStatus.dikerjakan;
    case 'selesai':
      return WoStatus.selesai;
    case 'dibatalkan':
      return WoStatus.dibatalkan;
    default:
      return WoStatus.menunggu;
  }
}
