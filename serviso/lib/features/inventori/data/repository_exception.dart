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

  if (error is PostgrestException) {
    final message = (error.message).toLowerCase();
    final code = error.code ?? '';
    if (code == '23505' || message.contains('parts_code_key')) {
      return _duplicatePartCodeMessage;
    }
    if (code == '23514' || message.contains('stock_qty')) {
      return _insufficientStockMessage;
    }
    if (message.isNotEmpty) return error.message;
    return 'Gagal memproses data. Coba lagi.';
  }

  final text = error.toString().toLowerCase();
  if (text.contains('parts_code_key')) return _duplicatePartCodeMessage;
  if (text.contains('stock_qty') || text.contains('check')) {
    return _insufficientStockMessage;
  }
  return 'Gagal memproses data. Coba lagi.';
}
