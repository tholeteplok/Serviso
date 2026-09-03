import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../features/auth/models/profile.dart';
import '../data/admin_repository.dart';
import '../data/audit_log_repository.dart';
import '../models/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (AppConfig.isConfigured) {
    return SupabaseAdminRepository(Supabase.instance.client);
  }
  return FakeAdminRepository();
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  if (AppConfig.isConfigured) {
    return SupabaseAuditLogRepository(Supabase.instance.client);
  }
  return FakeAuditLogRepository();
});

final userListProvider = FutureProvider<List<Profile>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listUsers();
});

final auditLogFilterProvider = StateProvider<AuditLogFilter>((ref) {
  return const AuditLogFilter();
});

final auditLogListProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final repo = ref.watch(auditLogRepositoryProvider);
  final filter = ref.watch(auditLogFilterProvider);
  return repo.fetchAuditLogs(filter: filter);
});

final platformSummaryProvider = FutureProvider<PlatformSummary>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPlatformSummary();
});

final platformShopSearchQueryProvider = StateProvider<String>((ref) => '');
final platformShopFilterStatusProvider = StateProvider<bool?>((ref) => null);

final platformShopsProvider = FutureProvider<List<ShopItem>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final search = ref.watch(platformShopSearchQueryProvider);
  final isActive = ref.watch(platformShopFilterStatusProvider);
  return repo.listShops(search: search, isActive: isActive);
});

final platformShopDetailProvider =
    FutureProvider.family<ShopItem, String>((ref, shopId) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getShopDetail(shopId);
});

final platformShopUsersProvider =
    FutureProvider.family<List<Profile>, String>((ref, shopId) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getShopUsers(shopId);
});

final platformShopStatsProvider =
    FutureProvider.family<ShopStats, String>((ref, shopId) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getShopStats(shopId);
});

