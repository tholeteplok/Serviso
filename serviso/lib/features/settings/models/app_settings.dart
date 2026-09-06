class AppSettings {
  const AppSettings({
    required this.shopName,
    this.address,
    this.phone,
    this.receiptNotes,
    this.businessType = 'keduanya',
  });

  final String shopName;
  final String? address;
  final String? phone;
  final String? receiptNotes;
  final String businessType;

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      shopName: (map['shop_name'] as String?) ?? (map['name'] as String?) ?? '',
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      receiptNotes: (map['receipt_notes'] as String?) ?? (map['notes'] as String?),
      businessType: (map['business_type'] as String?) ?? 'keduanya',
    );
  }

  AppSettings copyWith({
    String? shopName,
    String? address,
    String? phone,
    String? receiptNotes,
    String? businessType,
  }) =>
      AppSettings(
        shopName: shopName ?? this.shopName,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        receiptNotes: receiptNotes ?? this.receiptNotes,
        businessType: businessType ?? this.businessType,
      );

  Map<String, dynamic> toUpdateMap() => {
        'shop_name': shopName,
        'address': address?.trim().isEmpty == true ? null : address?.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'receipt_notes':
            receiptNotes?.trim().isEmpty == true ? null : receiptNotes?.trim(),
        'business_type': businessType,
      };
}

class SettingsInput {
  const SettingsInput({
    required this.shopName,
    this.address,
    this.phone,
    this.receiptNotes,
    this.businessType = 'keduanya',
  });

  final String shopName;
  final String? address;
  final String? phone;
  final String? receiptNotes;
  final String businessType;

  AppSettings toSettings() => AppSettings(
        shopName: shopName,
        address: address,
        phone: phone,
        receiptNotes: receiptNotes,
        businessType: businessType,
      );
}
