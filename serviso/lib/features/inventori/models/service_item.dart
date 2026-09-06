double _parseNumeric(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.price,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? code;
  final String? description;
  final double price;
  final bool isActive;
  final DateTime createdAt;

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    final rawCode = map['code'] as String?;
    final rawDesc = map['description'] as String?;
    return ServiceItem(
      id: map['id'] as String,
      name: (map['name'] as String? ?? '').trim(),
      code: rawCode?.trim().isEmpty == true ? null : rawCode?.trim(),
      description: rawDesc?.trim().isEmpty == true ? null : rawDesc?.trim(),
      price: _parseNumeric(map['price']),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'code': code?.trim().isEmpty == true ? null : code?.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'price': price,
      'is_active': isActive,
    };
  }

  ServiceItem copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    double? price,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ServiceInput {
  const ServiceInput({
    this.id,
    required this.name,
    this.code,
    this.description,
    required this.price,
    this.isActive = true,
  });

  final String? id;
  final String name;
  final String? code;
  final String? description;
  final double price;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'code': code?.trim().isEmpty == true ? null : code?.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'price': price,
      'is_active': isActive,
    };
  }
}
