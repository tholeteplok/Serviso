import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/models/profile.dart';
import '../../../features/inventori/data/repository_exception.dart';
import '../models/admin_models.dart';

abstract class AdminRepository {
  Future<List<Profile>> listUsers();
  Future<void> createUser(CreateUserPayload payload);
  Future<void> toggleUserActive(String userId, bool active);
  Future<void> sendResetPassword(String userId);

  // Platform Admin
  Future<PlatformSummary> getPlatformSummary();
  Future<List<ShopItem>> listShops({String? search, bool? isActive});
  Future<ShopItem> getShopDetail(String shopId);
  Future<List<Profile>> getShopUsers(String shopId);
  Future<ShopStats> getShopStats(String shopId);
  Future<void> setShopActive(String shopId, bool isActive);
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

  Future<Map<String, String>?> _buildAuthHeaders() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null && session.isExpired) {
        await _client.auth.refreshSession();
      }
      final token = _client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        return {'Authorization': 'Bearer $token'};
      }
    } catch (_) {
      // Abaikan jika refresh gagal, biarkan auth context bawaan klien mencoba
    }
    return null;
  }

  @override
  Future<void> createUser(CreateUserPayload payload) async {
    try {
      final headers = await _buildAuthHeaders();
      final res = await _client.functions.invoke(
        'manage-user',
        headers: headers,
        body: payload.toMap(),
      );
      if (res.status != 200) {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal membuat pengguna baru.';
        throw RepositoryException(errorMsg ?? 'Gagal membuat pengguna baru.');
      }
    } on FunctionException catch (fe) {
      throw RepositoryException(mapRepositoryError(fe));
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> toggleUserActive(String userId, bool active) async {
    try {
      final headers = await _buildAuthHeaders();
      final res = await _client.functions.invoke(
        'manage-user',
        headers: headers,
        body: {
          'action': active ? 'activate' : 'deactivate',
          'user_id': userId,
        },
      );
      if (res.status != 200) {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal mengubah status pengguna.';
        throw RepositoryException(errorMsg ?? 'Gagal mengubah status pengguna.');
      }
    } on FunctionException catch (fe) {
      throw RepositoryException(mapRepositoryError(fe));
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> sendResetPassword(String userId) async {
    try {
      final headers = await _buildAuthHeaders();
      final res = await _client.functions.invoke(
        'manage-user',
        headers: headers,
        body: {
          'action': 'reset_password',
          'user_id': userId,
        },
      );
      if (res.status != 200) {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal mengirim instruksi reset password.';
        throw RepositoryException(errorMsg ?? 'Gagal mengirim instruksi reset password.');
      }
    } on FunctionException catch (fe) {
      throw RepositoryException(mapRepositoryError(fe));
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<PlatformSummary> getPlatformSummary() async {
    try {
      final shopsRes = await _client.from('shops').select('id, is_active, created_at');
      final shops = shopsRes as List<dynamic>;

      int active = 0;
      int inactive = 0;
      int newThisMonth = 0;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (final s in shops) {
        final isActive = (s['is_active'] as bool?) ?? true;
        if (isActive) {
          active++;
        } else {
          inactive++;
        }
        if (s['created_at'] != null) {
          final dt = DateTime.tryParse(s['created_at'].toString());
          if (dt != null && dt.isAfter(startOfMonth)) {
            newThisMonth++;
          }
        }
      }

      final profilesRes = await _client
          .from('profiles')
          .select('id')
          .eq('is_platform_admin', false);
      final totalUsers = (profilesRes as List<dynamic>).length;

      return PlatformSummary(
        activeShopsCount: active,
        inactiveShopsCount: inactive,
        totalUsersCount: totalUsers,
        newShopsThisMonthCount: newThisMonth,
      );
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<ShopItem>> listShops({String? search, bool? isActive}) async {
    try {
      var query = _client.from('shops').select();
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      final data = await query.order('created_at', ascending: false);
      var list = (data as List).map((m) => ShopItem.fromMap(m)).toList();
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list
            .where((s) => s.name.toLowerCase().contains(q) || s.slug.toLowerCase().contains(q))
            .toList();
      }
      return list;
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<ShopItem> getShopDetail(String shopId) async {
    try {
      final data = await _client.from('shops').select().eq('id', shopId).maybeSingle();
      if (data == null) {
        throw const RepositoryException('Toko tidak ditemukan.');
      }
      return ShopItem.fromMap(data);
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<List<Profile>> getShopUsers(String shopId) async {
    try {
      final data =
          await _client.from('profiles').select().eq('shop_id', shopId).order('created_at');
      return (data as List).map((m) => Profile.fromMap(m)).toList();
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<ShopStats> getShopStats(String shopId) async {
    try {
      final woRes = await _client.from('work_orders').select('id').eq('shop_id', shopId);
      final custRes = await _client.from('customers').select('id').eq('shop_id', shopId);
      final saleRes = await _client.from('direct_sales').select('id').eq('shop_id', shopId);
      final userRes = await _client.from('profiles').select('id').eq('shop_id', shopId);

      return ShopStats(
        totalWorkOrders: (woRes as List).length,
        totalCustomers: (custRes as List).length,
        totalDirectSales: (saleRes as List).length,
        totalUsers: (userRes as List).length,
      );
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }

  @override
  Future<void> setShopActive(String shopId, bool isActive) async {
    try {
      await _client.rpc('set_shop_active', params: {
        'p_shop_id': shopId,
        'p_is_active': isActive,
      });
    } catch (e) {
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

  List<ShopItem> mockShops = [
    ShopItem(
      id: 'shop-1',
      name: 'Bengkel Maju Jaya',
      slug: 'maju-jaya',
      isActive: true,
      address: 'Jl. Merdeka No. 10',
      phone: '081234567890',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ShopItem(
      id: 'shop-2',
      name: 'Bengkel Berkah Abadi',
      slug: 'berkah-abadi',
      isActive: false,
      address: 'Jl. Pemuda No. 5',
      phone: '081298765432',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
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

  @override
  Future<PlatformSummary> getPlatformSummary() async {
    final active = mockShops.where((s) => s.isActive).length;
    final inactive = mockShops.where((s) => !s.isActive).length;
    final totalUsers = mockProfiles.length;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final newThisMonth = mockShops.where((s) => s.createdAt.isAfter(startOfMonth)).length;

    return PlatformSummary(
      activeShopsCount: active,
      inactiveShopsCount: inactive,
      totalUsersCount: totalUsers,
      newShopsThisMonthCount: newThisMonth,
    );
  }

  @override
  Future<List<ShopItem>> listShops({String? search, bool? isActive}) async {
    var list = List<ShopItem>.from(mockShops);
    if (isActive != null) {
      list = list.where((s) => s.isActive == isActive).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where((s) => s.name.toLowerCase().contains(q) || s.slug.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Future<ShopItem> getShopDetail(String shopId) async {
    final s = mockShops.where((el) => el.id == shopId).firstOrNull;
    if (s == null) {
      throw const RepositoryException('Toko tidak ditemukan.');
    }
    return s;
  }

  @override
  Future<List<Profile>> getShopUsers(String shopId) async {
    return mockProfiles.where((p) => p.shopId == shopId || shopId == 'shop-1').toList();
  }

  @override
  Future<ShopStats> getShopStats(String shopId) async {
    return const ShopStats(
      totalWorkOrders: 12,
      totalCustomers: 8,
      totalDirectSales: 25,
      totalUsers: 2,
    );
  }

  @override
  Future<void> setShopActive(String shopId, bool isActive) async {
    final idx = mockShops.indexWhere((s) => s.id == shopId);
    if (idx != -1) {
      final current = mockShops[idx];
      mockShops[idx] = ShopItem(
        id: current.id,
        name: current.name,
        slug: current.slug,
        isActive: isActive,
        address: current.address,
        phone: current.phone,
        createdAt: current.createdAt,
      );
    }
  }
}
