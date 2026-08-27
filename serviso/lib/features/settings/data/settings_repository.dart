import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/session_controller.dart';
import '../models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<AppSettings> updateSettings({
    required String shopName,
    String? address,
    String? phone,
  });
}

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AppSettings> getSettings() async {
    try {
      final data = await _client
          .from('app_settings')
          .select('shop_name, address, phone')
          .eq('id', 1)
          .maybeSingle();
      if (data == null) {
        return const AppSettings(shopName: 'Bengkel Serviso');
      }
      return AppSettings.fromMap(data);
    } catch (e) {
      return const AppSettings(shopName: 'Bengkel Serviso');
    }
  }

  @override
  Future<AppSettings> updateSettings({
    required String shopName,
    String? address,
    String? phone,
  }) async {
    final updated = await _client
        .from('app_settings')
        .update({
          'shop_name': shopName,
          'address': address?.trim().isEmpty == true ? null : address?.trim(),
          'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        })
        .eq('id', 1)
        .select('shop_name, address, phone')
        .maybeSingle();
    if (updated == null) {
      throw const SettingsException('Pengaturan gagal diperbarui');
    }
    return AppSettings.fromMap(updated);
  }
}

class SettingsException implements Exception {
  const SettingsException(this.message);

  final String message;

  @override
  String toString() => message;
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SupabaseSettingsRepository(ref.watch(supabaseClientProvider));
});

final settingsProvider = FutureProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).getSettings();
});

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.failUpdate = false,
    this.allowAdmin = true,
  });

  AppSettings _settings =
      const AppSettings(shopName: 'Bengkel Serviso', address: null, phone: null);

  bool failUpdate;
  final bool allowAdmin;

  AppSettings get current => _settings;

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<AppSettings> updateSettings({
    required String shopName,
    String? address,
    String? phone,
  }) async {
    if (!allowAdmin) {
      throw const SettingsException(
        'Hanya pemilik yang dapat mengubah pengaturan',
      );
    }
    if (failUpdate) {
      throw const SettingsException('Pengaturan gagal diperbarui');
    }
    _settings = AppSettings(
      shopName: shopName,
      address: address,
      phone: phone,
    );
    return _settings;
  }
}
