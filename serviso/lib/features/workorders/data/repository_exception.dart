import 'package:supabase_flutter/supabase_flutter.dart';

class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

String mapRepositoryError(Object error) {
  if (error is RepositoryException) return error.message;

  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';
    if (code == '23514' || message.contains('stock')) {
      return 'Stok tidak cukup untuk menyelesaikan work order';
    }
    if (message.isNotEmpty) return error.message;
    return 'Gagal memproses work order. Coba lagi.';
  }

  final text = error.toString().toLowerCase();
  if (text.contains('stock')) {
    return 'Stok tidak cukup untuk menyelesaikan work order';
  }
  return 'Gagal memproses work order. Coba lagi.';
}
