class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.vehicleCount = 0,
    this.workOrderCount = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final int vehicleCount;
  final int workOrderCount;
  final DateTime createdAt;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: (map['name'] as String? ?? '').trim(),
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      note: map['note'] as String?,
      vehicleCount: _vehicleCount(map),
      workOrderCount: (map['work_order_count'] as int?) ?? 0,
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at'] as String),
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? note,
    int? vehicleCount,
    int? workOrderCount,
    DateTime? createdAt,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        note: note ?? this.note,
        vehicleCount: vehicleCount ?? this.vehicleCount,
        workOrderCount: workOrderCount ?? this.workOrderCount,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'note': note,
        'vehicle_count': vehicleCount,
        'work_order_count': workOrderCount,
        'created_at': createdAt.toIso8601String(),
      };

  static int _vehicleCount(Map<String, dynamic> map) {
    final vehicles = map['vehicles'];
    if (vehicles is List && vehicles.isNotEmpty) {
      final first = vehicles.first;
      if (first is Map && first['count'] != null) {
        return first['count'] as int;
      }
    }
    return 0;
  }
}

class CustomerInput {
  const CustomerInput({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
  });

  final String? id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'address': address?.trim().isEmpty == true ? null : address?.trim(),
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
      };
}
