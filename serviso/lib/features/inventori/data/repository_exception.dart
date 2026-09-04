import 'package:supabase_flutter/supabase_flutter.dart';

class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _duplicatePartCodeMessage = 'Kode suku cadang sudah digunakan';
const _insufficientStockMessage = 'Stok tidak cukup untuk koreksi ini';

String mapRepositoryError(Object error) {
  if (error is RepositoryException) return error.message;

  if (error is FunctionException) {
    final details = error.details;
    if (details is Map) {
      final msg = details['error'] ?? details['message'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return _humanizeErrorMessage(msg.toString());
      }
    } else if (details is String && details.trim().isNotEmpty) {
      return _humanizeErrorMessage(details);
    }
    if (error.reasonPhrase != null && error.reasonPhrase!.isNotEmpty) {
      return 'Kesalahan server (${error.status}): ${error.reasonPhrase}';
    }
    return 'Terjadi kesalahan pada server (${error.status}). Coba lagi.';
  }

  if (error is PostgrestException) {
    final message = (error.message).toLowerCase();
    final code = error.code ?? '';
    if (code == '23505' || message.contains('parts_code_key')) {
      return _duplicatePartCodeMessage;
    }
    if (code == '23514' || message.contains('stock_qty')) {
      return _insufficientStockMessage;
    }
    if (message.isNotEmpty) return _humanizeErrorMessage(error.message);
    return 'Gagal memproses data. Coba lagi.';
  }

  final text = error.toString().toLowerCase();
  if (text.contains('parts_code_key')) return _duplicatePartCodeMessage;
  if (text.contains('stock_qty') || text.contains('check')) {
    return _insufficientStockMessage;
  }
  return _humanizeErrorMessage(error.toString());
}

String _humanizeErrorMessage(String message) {
  var clean = message.trim();
  if (clean.startsWith('Exception: ')) {
    clean = clean.substring('Exception: '.length).trim();
  }
  final lower = clean.toLowerCase();
  if (lower.contains('a user with this email already exists') ||
      lower.contains('user already registered')) {
    return 'Akun atau email ini sudah terdaftar di sistem. Gunakan username lain.';
  }
  if (lower.contains('password should be at least 6 characters')) {
    return 'Password minimal 6 karakter.';
  }
  if (lower.contains('email is not valid') || lower.contains('invalid email')) {
    return 'Format email atau username tidak valid.';
  }
  return clean;
}
