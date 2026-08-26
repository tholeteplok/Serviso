import '../../../core/utils/formatters.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.plateNo,
    this.brand,
    this.model,
    this.year,
    this.color,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String plateNo;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final DateTime createdAt;

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      plateNo: plate((map['plate_no'] as String? ?? '').trim()),
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      year: map['year'] as int?,
      color: map['color'] as String?,
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at'] as String),
    );
  }

  Vehicle copyWith({
    String? id,
    String? customerId,
    String? plateNo,
    String? brand,
    String? model,
    int? year,
    String? color,
    DateTime? createdAt,
  }) =>
      Vehicle(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        plateNo: plateNo ?? this.plateNo,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        year: year ?? this.year,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'plate_no': plate(plateNo),
        'brand': brand,
        'model': model,
        'year': year,
        'color': color,
        'created_at': createdAt.toIso8601String(),
      };
}

class VehicleInput {
  const VehicleInput({
    this.id,
    required this.customerId,
    required this.plateNo,
    this.brand,
    this.model,
    this.year,
    this.color,
  });

  final String? id;
  final String customerId;
  final String plateNo;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;

  Map<String, dynamic> toMap({bool includeCustomerId = true}) {
    final map = <String, dynamic>{
      'plate_no': plate(plateNo),
      'brand': brand?.trim().isEmpty == true ? null : brand?.trim(),
      'model': model?.trim().isEmpty == true ? null : model?.trim(),
      'year': year,
      'color': color?.trim().isEmpty == true ? null : color?.trim(),
    };
    if (includeCustomerId) map['customer_id'] = customerId;
    return map;
  }
}
