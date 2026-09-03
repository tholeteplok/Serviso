enum UserRole { admin, kasir, mekanik }

class Profile {
  const Profile({
    required this.id,
    required this.username,
    this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.phone,
    this.shopId,
    this.shopName,
    this.shopSlug,
    this.isPlatformAdmin = false,
  });

  final String id;
  final String username;
  final String? email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String? phone;
  final String? shopId;
  final String? shopName;
  final String? shopSlug;
  final bool isPlatformAdmin;

  bool get isAdmin => role == UserRole.admin;

  factory Profile.fromMap(Map<String, dynamic> map) {
    final shopsMap = map['shops'] as Map?;
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      fullName: (map['full_name'] as String?) ?? '',
      role: _roleFromString(map['role'] as String?),
      isActive: (map['is_active'] as bool?) ?? true,
      phone: map['phone'] as String?,
      shopId: map['shop_id'] as String?,
      shopName: (shopsMap?['name'] as String?) ?? (map['shop_name'] as String?),
      shopSlug: (shopsMap?['slug'] as String?) ?? (map['shop_slug'] as String?),
      isPlatformAdmin: (map['is_platform_admin'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'email': email,
        'full_name': fullName,
        'role': _roleToString(role),
        'is_active': isActive,
        'phone': phone,
        'shop_id': shopId,
        'shop_slug': shopSlug,
        'is_platform_admin': isPlatformAdmin,
      };

  Profile copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    UserRole? role,
    bool? isActive,
    String? phone,
    String? shopId,
    String? shopName,
    String? shopSlug,
    bool? isPlatformAdmin,
  }) =>
      Profile(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        phone: phone ?? this.phone,
        shopId: shopId ?? this.shopId,
        shopName: shopName ?? this.shopName,
        shopSlug: shopSlug ?? this.shopSlug,
        isPlatformAdmin: isPlatformAdmin ?? this.isPlatformAdmin,
      );
}

UserRole _roleFromString(String? value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'mekanik':
      return UserRole.mekanik;
    case 'kasir':
    default:
      return UserRole.kasir;
  }
}

String _roleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.mekanik:
      return 'mekanik';
    case UserRole.kasir:
      return 'kasir';
  }
}

const Map<UserRole, String> userRoleLabel = {
  UserRole.admin: 'Pemilik',
  UserRole.kasir: 'Kasir',
  UserRole.mekanik: 'Mekanik',
};

