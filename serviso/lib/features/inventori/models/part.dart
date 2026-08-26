double parseNumeric(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class Part {
  const Part({
    required this.id,
    required this.name,
    this.code,
    this.unit,
    this.minStock = 0,
    this.costPrice = 0,
    this.sellPrice = 0,
    required this.stockQty,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? code;
  final String? unit;
  final int minStock;
  final double costPrice;
  final double sellPrice;
  final double stockQty;
  final DateTime createdAt;

  factory Part.fromMap(Map<String, dynamic> map) {
    final rawUnit = map['unit'] as String?;
    final rawCode = map['code'] as String?;
    return Part(
      id: map['id'] as String,
      name: (map['name'] as String? ?? '').trim(),
      code: rawCode?.trim().isEmpty == true ? null : rawCode?.trim(),
      unit: rawUnit?.trim().isEmpty == true ? null : rawUnit?.trim(),
      minStock: (map['min_stock'] as int?) ?? 0,
      costPrice: parseNumeric(map['cost_price']),
      sellPrice: parseNumeric(map['sell_price']),
      stockQty: parseNumeric(map['stock_qty']),
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isLowStock => stockQty <= minStock;

  Part copyWith({
    String? id,
    String? name,
    String? code,
    String? unit,
    int? minStock,
    double? costPrice,
    double? sellPrice,
    double? stockQty,
    DateTime? createdAt,
  }) =>
      Part(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        unit: unit ?? this.unit,
        minStock: minStock ?? this.minStock,
        costPrice: costPrice ?? this.costPrice,
        sellPrice: sellPrice ?? this.sellPrice,
        stockQty: stockQty ?? this.stockQty,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name.trim(),
        'code': code?.trim().isEmpty == true ? null : code?.trim(),
        'unit': unit?.trim().isEmpty == true ? 'pcs' : unit?.trim(),
        'min_stock': minStock,
        'cost_price': costPrice,
        'sell_price': sellPrice,
        'stock_qty': stockQty,
        'created_at': createdAt.toIso8601String(),
      };
}

class PartInput {
  const PartInput({
    this.id,
    required this.name,
    this.code,
    this.unit,
    this.minStock = 0,
    this.costPrice = 0,
    this.sellPrice = 0,
  });

  final String? id;
  final String name;
  final String? code;
  final String? unit;
  final int minStock;
  final double costPrice;
  final double sellPrice;

  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'name': name.trim(),
      'code': code?.trim().isEmpty == true ? null : code?.trim(),
      'unit': unit?.trim().isEmpty == true ? 'pcs' : unit?.trim(),
      'min_stock': minStock,
      'cost_price': costPrice,
      'sell_price': sellPrice,
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }
}

String suggestPartCode() {
  final stamp = DateTime.now().microsecondsSinceEpoch % 100000;
  return 'P${stamp.toString().padLeft(5, '0')}';
}
