import 'part.dart';

enum MovementDirection { in_, out, adjust }

enum MovementRef { pembelian, wo, koreksi, pembatalan }

class PartMovement {
  const PartMovement({
    required this.id,
    required this.partId,
    required this.direction,
    required this.qty,
    required this.refType,
    this.refId,
    this.note,
    this.actorName,
    this.distributor,
    this.purchasePrice,
    this.paymentType = 'tunai',
    this.debtStatus = 'lunas',
    this.dueDate,
    this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String partId;
  final MovementDirection direction;
  final double qty;
  final MovementRef refType;
  final String? refId;
  final String? note;
  final String? actorName;
  final String? distributor;
  final double? purchasePrice;
  final String paymentType;
  final String debtStatus;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime createdAt;

  factory PartMovement.fromMap(Map<String, dynamic> map) {
    final profiles = map['profiles'];
    final actorName = profiles is Map ? (profiles['full_name'] as String?) : null;
    return PartMovement(
      id: map['id'] as String,
      partId: map['part_id'] as String,
      direction: _directionFromString(map['direction'] as String?),
      qty: parseNumeric(map['qty']),
      refType: _refFromString(map['ref_type'] as String?),
      refId: map['ref_id'] as String?,
      note: map['note'] as String?,
      actorName: actorName,
      distributor: map['distributor'] as String?,
      purchasePrice: map['purchase_price'] != null
          ? parseNumeric(map['purchase_price'])
          : null,
      paymentType: (map['payment_type'] as String?) ?? 'tunai',
      debtStatus: (map['debt_status'] as String?) ?? 'lunas',
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      paidAt: map['paid_at'] != null
          ? DateTime.tryParse(map['paid_at'].toString())
          : null,
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isDebt => paymentType == 'hutang';
  bool get isUnpaidDebt => isDebt && debtStatus == 'belum_lunas';
  double get totalPurchaseAmount => qty * (purchasePrice ?? 0);

  double get signedDelta {
    switch (direction) {
      case MovementDirection.in_:
        return qty;
      case MovementDirection.out:
        return -qty;
      case MovementDirection.adjust:
        return qty;
    }
  }

  double get signedQuantity {
    switch (direction) {
      case MovementDirection.in_:
        return qty;
      case MovementDirection.out:
        return -qty;
      case MovementDirection.adjust:
        return qty;
    }
  }

  PartMovement copyWith({
    String? id,
    String? partId,
    MovementDirection? direction,
    double? qty,
    MovementRef? refType,
    String? refId,
    String? note,
    String? actorName,
    String? distributor,
    double? purchasePrice,
    String? paymentType,
    String? debtStatus,
    DateTime? dueDate,
    DateTime? paidAt,
    DateTime? createdAt,
  }) =>
      PartMovement(
        id: id ?? this.id,
        partId: partId ?? this.partId,
        direction: direction ?? this.direction,
        qty: qty ?? this.qty,
        refType: refType ?? this.refType,
        refId: refId ?? this.refId,
        note: note ?? this.note,
        actorName: actorName ?? this.actorName,
        distributor: distributor ?? this.distributor,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        paymentType: paymentType ?? this.paymentType,
        debtStatus: debtStatus ?? this.debtStatus,
        dueDate: dueDate ?? this.dueDate,
        paidAt: paidAt ?? this.paidAt,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'part_id': partId,
        'direction': _directionToString(direction),
        'qty': qty,
        'ref_type': _refToString(refType),
        'ref_id': refId,
        'note': note,
        'distributor': distributor,
        'purchase_price': purchasePrice,
        'payment_type': paymentType,
        'debt_status': debtStatus,
        'due_date': dueDate?.toIso8601String().substring(0, 10),
        'paid_at': paidAt?.toIso8601String(),
      };
}

MovementDirection _directionFromString(String? value) {
  switch (value) {
    case 'in':
      return MovementDirection.in_;
    case 'out':
      return MovementDirection.out;
    case 'adjust':
    default:
      return MovementDirection.adjust;
  }
}

String _directionToString(MovementDirection direction) {
  switch (direction) {
    case MovementDirection.in_:
      return 'in';
    case MovementDirection.out:
      return 'out';
    case MovementDirection.adjust:
      return 'adjust';
  }
}

MovementRef _refFromString(String? value) {
  switch (value) {
    case 'pembelian':
      return MovementRef.pembelian;
    case 'wo':
      return MovementRef.wo;
    case 'koreksi':
      return MovementRef.koreksi;
    case 'pembatalan':
      return MovementRef.pembatalan;
    default:
      return MovementRef.pembelian;
  }
}

String _refToString(MovementRef ref) {
  switch (ref) {
    case MovementRef.pembelian:
      return 'pembelian';
    case MovementRef.wo:
      return 'wo';
    case MovementRef.koreksi:
      return 'koreksi';
    case MovementRef.pembatalan:
      return 'pembatalan';
  }
}

const Map<MovementRef, String> movementRefLabel = {
  MovementRef.pembelian: 'Pembelian',
  MovementRef.wo: 'Work Order',
  MovementRef.koreksi: 'Koreksi',
  MovementRef.pembatalan: 'Pembatalan',
};
