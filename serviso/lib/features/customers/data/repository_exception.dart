import 'package:supabase_flutter/supabase_flutter.dart';

class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _duplicatePlateMessage = 'Plat nomor sudah terdaftar';
const _restrictedDeleteMessage = 'Hapus dulu kendaraan milik pelanggan ini';

String mapRepositoryError(Object error) {
  if (error is RepositoryException) return error.message;

  if (error is PostgrestException) {
    final message = (error.message).toLowerCase();
    final code = error.code ?? '';
    if (code == '23505' || message.contains('plate_no')) {
      return _duplicatePlateMessage;
    }
    if (code == '23503' ||
        message.contains('restrict') ||
        message.contains('vehicles_customer_id_fkey')) {
      return _restrictedDeleteMessage;
    }
    if (message.isNotEmpty) return error.message;
    return 'Gagal memproses data. Coba lagi.';
  }

  final text = error.toString().toLowerCase();
  if (text.contains('plate_no')) return _duplicatePlateMessage;
  if (text.contains('restrict') || text.contains('vehicles_customer_id_fkey')) {
    return _restrictedDeleteMessage;
  }
  return 'Gagal memproses data. Coba lagi.';
}
