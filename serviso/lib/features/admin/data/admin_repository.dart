import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/models/profile.dart';
import '../../../features/inventori/data/repository_exception.dart';
import '../models/admin_models.dart';

abstract class AdminRepository {
  Future<List<Profile>> listUsers();
  Future<void> createUser(CreateUserPayload payload);
  Future<void> toggleUserActive(String userId, bool active);
  Future<void> sendResetPassword(String userId);
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Profile>> listUsers() async {
    try {
      final data = await _client.from('profiles').select().order('created_at');
      return (data as List).map((m) => Profile.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> createUser(CreateUserPayload payload) async {
    try {
      final res = await _client.functions.invoke('manage-user', body: payload.toMap());
      if (res.status != 200) {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal membuat pengguna baru.';
        throw RepositoryException(errorMsg ?? 'Gagal membuat pengguna baru.');
      }
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> toggleUserActive(String userId, bool active) async {
    try {
      final res = await _client.functions.invoke('manage-user', body: {
        'action': active ? 'activate' : 'deactivate',
        'user_id': userId,
      });
      if (res.status != 200) {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal mengubah status pengguna.';
        throw RepositoryException(errorMsg ?? 'Gagal mengubah status pengguna.');
      }
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> sendResetPassword(String userId) async {
    try {
      final res = await _client.functions.invoke('manage-user', body: {
        'action': 'reset_password',
        'user_id': userId,
      });
      if (res.status != 200) {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal mengirim instruksi reset password.';
        throw RepositoryException(errorMsg ?? 'Gagal mengirim instruksi reset password.');
      }
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException(mapRepositoryError(e));
    }
  }
}

class FakeAdminRepository implements AdminRepository {
  List<Profile> mockProfiles = [
    const Profile(
      id: 'u1',
      username: 'admin',
      fullName: 'Pemilik Bengkel',
      role: UserRole.admin,
      isActive: true,
      email: 'owner@serviso.app',
    ),
    const Profile(
      id: 'u2',
      username: 'kasir1',
      fullName: 'Budi Kasir',
      role: UserRole.kasir,
      isActive: true,
      email: 'budi@serviso.app',
    ),
  ];

  @override
  Future<List<Profile>> listUsers() async => List.from(mockProfiles);

  @override
  Future<void> createUser(CreateUserPayload payload) async {
    if (mockProfiles.any((p) => p.username == payload.username.trim().toLowerCase())) {
      throw RepositoryException("Username '${payload.username}' sudah digunakan.");
    }
    final newProfile = Profile(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      username: payload.username.trim().toLowerCase(),
      fullName: payload.fullName.trim(),
      role: payload.role,
      isActive: true,
      email: payload.email,
    );
    mockProfiles.add(newProfile);
  }

  @override
  Future<void> toggleUserActive(String userId, bool active) async {
    final idx = mockProfiles.indexWhere((p) => p.id == userId);
    if (idx != -1) {
      final p = mockProfiles[idx];
      mockProfiles[idx] = Profile(
        id: p.id,
        username: p.username,
        fullName: p.fullName,
        role: p.role,
        isActive: active,
        email: p.email,
        phone: p.phone,
      );
    }
  }

  @override
  Future<void> sendResetPassword(String userId) async {
    // No-op for fake
  }
}
