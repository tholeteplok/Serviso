String? validateCustomerName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nama pelanggan wajib diisi';
  }
  return null;
}

String? validatePlate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Plat nomor wajib diisi';
  }
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  if (normalized.length < 3 || normalized.length > 12) {
    return 'Format plat tidak valid';
  }
  // Format Indonesia: 1-2 huruf, 1-4 angka, 1-3 huruf (spasi opsional, sudah dinormalisasi)
  final platePattern = RegExp(r'^[A-Z]{1,2}\s\d{1,4}\s?[A-Z]{1,3}$');
  if (!platePattern.hasMatch(normalized) && !RegExp(r'^[A-Z0-9\s]+$').hasMatch(normalized)) {
    return 'Format plat tidak valid';
  }
  return null;
}

String? validateCustomerPhone(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final hasValidChars = RegExp(r'^[0-9+\-\s()]+$').hasMatch(trimmed);
  if (!hasValidChars || trimmed.replaceAll(RegExp(r'[^0-9]'), '').length < 5) {
    return 'Nomor telepon tidak valid';
  }
  return null;
}
