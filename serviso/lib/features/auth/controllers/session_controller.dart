import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../models/profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sessionProvider =
    AsyncNotifierProvider<SessionController, Profile?>(SessionController.new);

final isAdminProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session.valueOrNull?.isAdmin ?? false;
});

class SessionController extends AsyncNotifier<Profile?> {
  late final AuthRepository _auth;

  @override
  Future<Profile?> build() async {
    _auth = ref.watch(authRepositoryProvider);
    try {
      return await _auth.currentProfile().timeout(
            const Duration(seconds: 4),
            onTimeout: () => null,
          );
    } catch (_) {
      return null;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final profile = await _auth.login(username: username, password: password);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncData(null);
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    final updated = await _auth.updateProfile(
      fullName: fullName,
      phone: phone,
    );
    state = AsyncData(updated);
  }
}
