class AppSettings {
  const AppSettings({
    required this.shopName,
    this.address,
    this.phone,
  });

  final String shopName;
  final String? address;
  final String? phone;

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      shopName: (map['shop_name'] as String?) ?? '',
      address: map['address'] as String?,
      phone: map['phone'] as String?,
    );
  }

  AppSettings copyWith({
    String? shopName,
    String? address,
    String? phone,
  }) =>
      AppSettings(
        shopName: shopName ?? this.shopName,
        address: address ?? this.address,
        phone: phone ?? this.phone,
      );

  Map<String, dynamic> toUpdateMap() => {
        'shop_name': shopName,
        'address': address?.trim().isEmpty == true ? null : address?.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      };
}

class SettingsInput {
  const SettingsInput({
    required this.shopName,
    this.address,
    this.phone,
  });

  final String shopName;
  final String? address;
  final String? phone;

  AppSettings toSettings() => AppSettings(
        shopName: shopName,
        address: address,
        phone: phone,
      );
}
