import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

String resolveLoginEmail(String identifier, String shopSlug) {
  final clean = identifier.trim().toLowerCase();
  final cleanSlug = shopSlug.trim().toLowerCase();
  if (clean.contains('@')) {
    return clean;
  }
  return '$clean.$cleanSlug@users.serviso.app';
}

abstract class AuthRepository {
  Future<Profile> login({required String username, required String password, required String shopSlug});

  Future<void> logout();

  Stream<Profile?> watchSession();

  Future<Profile?> currentProfile();

  Future<Profile> updateProfile({String? fullName, String? phone});
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile> login({
    required String username,
    required String password,
    required String shopSlug,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: resolveLoginEmail(username, shopSlug),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Username atau password salah');
      }
      final profile = await _fetchProfile(user.id);
      if (!profile.isActive) {
        await _client.auth.signOut();
        throw const AuthException(
          'Akun dinonaktifkan. Hubungi pemilik bengkel.',
        );
      }
      await _recordEvent('login');
      return profile;
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_mapApiError(e));
    } on SocketException {
      throw const AuthException('Tidak ada koneksi internet');
    } catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> logout() async {
    await _recordEvent('logout');
    await _client.auth.signOut();
  }

  @override
  Stream<Profile?> watchSession() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      try {
        return await _fetchProfile(user.id);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<Profile?> currentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Profile> updateProfile({String? fullName, String? phone}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan masuk kembali.');
    }
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    final data = await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .maybeSingle();
    if (data == null) {
      throw const AuthException('Profil gagal diperbarui. Coba lagi.');
    }
    return Profile.fromMap(data);
  }

  Future<Profile> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) {
      throw const AuthException(
        'Profil tidak ditemukan. Hubungi pemilik bengkel.',
      );
    }
    return Profile.fromMap(data);
  }

  Future<void> _recordEvent(String event) async {
    try {
      await _client.rpc('record_auth_event', params: {'p_event': event});
    } catch (_) {
      // best-effort audit; jangan gagalkan alur login/logout
    }
  }

  String _mapApiError(AuthApiException e) {
    final message = e.message.toLowerCase();
    final noNetwork = e.statusCode == null ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('timed out') ||
        message.contains('host') ||
        message.contains('failed to reach');
    if (noNetwork) return 'Tidak ada koneksi internet';
    return 'Username atau password salah';
  }

  String _mapError(Object e) {
    final message = e.toString().toLowerCase();
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timed out') ||
        message.contains('host')) {
      return 'Tidak ada koneksi internet';
    }
    return 'Username atau password salah';
  }
}

class FakeAuthRepository implements AuthRepository {
  Profile? profileToReturn;
  bool failLogin = false;
  bool networkError = false;
  bool logoutCalled = false;
  bool recordEventThrows = false;

  Profile? _current;
  final _sessionController = StreamController<Profile?>.broadcast();

  @override
  Future<Profile> login({
    required String username,
    required String password,
    required String shopSlug,
  }) async {
    if (networkError) {
      throw const AuthException('Tidak ada koneksi internet');
    }
    if (failLogin) {
      throw const AuthException('Username atau password salah');
    }
    final profile = profileToReturn;
    if (profile == null) {
      throw const AuthException('Profil tidak ditemukan. Hubungi pemilik bengkel.');
    }
    _current = profile;
    _sessionController.add(profile);
    return profile;
  }

  @override
  Future<void> logout() async {
    try {
      await _recordEvent('logout');
    } catch (_) {
      // best-effort audit: kegagalan record_auth_event tidak menggagalkan logout
    }
    logoutCalled = true;
    _current = null;
    _sessionController.add(null);
  }

  @override
  Stream<Profile?> watchSession() => _sessionController.stream;

  Future<void> _recordEvent(String event) async {
    if (recordEventThrows) {
      throw Exception('record_auth_event gagal: $event');
    }
  }

  @override
  Future<Profile?> currentProfile() async => _current ?? profileToReturn;

  @override
  Future<Profile> updateProfile({String? fullName, String? phone}) async {
    final current = _current;
    if (current == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan masuk kembali.');
    }
    final updated = current.copyWith(
      fullName: fullName ?? current.fullName,
      phone: phone ?? current.phone,
    );
    _current = updated;
    _sessionController.add(updated);
    return updated;
  }
}


