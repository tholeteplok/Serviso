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
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at'] as String),
    );
  }

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

  PartMovement copyWith({
    String? id,
    String? partId,
    MovementDirection? direction,
    double? qty,
    MovementRef? refType,
    String? refId,
    String? note,
    String? actorName,
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
