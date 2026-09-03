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
    String? receiptNotes,
  });
}

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AppSettings> getSettings() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('shop_id')
            .eq('id', user.id)
            .maybeSingle();
        final shopId = profile?['shop_id'] as String?;
        if (shopId != null) {
          final shop = await _client
              .from('shops')
              .select('name, address, phone, receipt_notes')
              .eq('id', shopId)
              .maybeSingle();
          if (shop != null) {
            return AppSettings(
              shopName: (shop['name'] as String?) ?? 'Bengkel Serviso',
              address: shop['address'] as String?,
              phone: shop['phone'] as String?,
              receiptNotes: shop['receipt_notes'] as String?,
            );
          }
        }
      }
    } catch (_) {}

    try {
      final data = await _client
          .from('app_settings')
          .select('shop_name, address, phone, receipt_notes')
          .eq('id', 1)
          .maybeSingle();
      if (data != null) {
        return AppSettings.fromMap(data);
      }
    } catch (_) {}

    return const AppSettings(shopName: 'Bengkel Serviso');
  }

  @override
  Future<AppSettings> updateSettings({
    required String shopName,
    String? address,
    String? phone,
    String? receiptNotes,
  }) async {
    final cleanAddress =
        address?.trim().isEmpty == true ? null : address?.trim();
    final cleanPhone = phone?.trim().isEmpty == true ? null : phone?.trim();
    final cleanReceiptNotes =
        receiptNotes?.trim().isEmpty == true ? null : receiptNotes?.trim();

    final user = _client.auth.currentUser;
    String? shopId;
    if (user != null) {
      try {
        final profile = await _client
            .from('profiles')
            .select('shop_id')
            .eq('id', user.id)
            .maybeSingle();
        shopId = profile?['shop_id'] as String?;
      } catch (_) {}
    }

    if (shopId != null) {
      try {
        final updated = await _client
            .from('shops')
            .update({
              'name': shopName,
              'address': cleanAddress,
              'phone': cleanPhone,
              'receipt_notes': cleanReceiptNotes,
            })
            .eq('id', shopId)
            .select('name, address, phone, receipt_notes')
            .maybeSingle();
        if (updated != null) {
          return AppSettings(
            shopName: (updated['name'] as String?) ?? shopName,
            address: updated['address'] as String?,
            phone: updated['phone'] as String?,
            receiptNotes: updated['receipt_notes'] as String?,
          );
        }
      } catch (e) {
        throw SettingsException(
          e is PostgrestException ? e.message : 'Pengaturan gagal diperbarui',
        );
      }
    }

    try {
      final updated = await _client
          .from('app_settings')
          .update({
            'shop_name': shopName,
            'address': cleanAddress,
            'phone': cleanPhone,
            'receipt_notes': cleanReceiptNotes,
          })
          .eq('id', 1)
          .select('shop_name, address, phone, receipt_notes')
          .maybeSingle();
      if (updated != null) {
        return AppSettings.fromMap(updated);
      }
    } catch (e) {
      if (shopId == null) {
        throw SettingsException(
          e is PostgrestException ? e.message : 'Pengaturan gagal diperbarui',
        );
      }
    }

    return AppSettings(
      shopName: shopName,
      address: cleanAddress,
      phone: cleanPhone,
      receiptNotes: cleanReceiptNotes,
    );
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

  AppSettings _settings = const AppSettings(
    shopName: 'Bengkel Serviso',
    address: null,
    phone: null,
    receiptNotes: null,
  );

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
    String? receiptNotes,
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
      receiptNotes: receiptNotes,
    );
    return _settings;
  }
}
