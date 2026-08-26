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
  });

  final String id;
  final String username;
  final String? email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String? phone;

  bool get isAdmin => role == UserRole.admin;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      fullName: (map['full_name'] as String?) ?? '',
      role: _roleFromString(map['role'] as String?),
      isActive: (map['is_active'] as bool?) ?? true,
      phone: map['phone'] as String?,
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
      };

  Profile copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    UserRole? role,
    bool? isActive,
    String? phone,
  }) =>
      Profile(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        phone: phone ?? this.phone,
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
