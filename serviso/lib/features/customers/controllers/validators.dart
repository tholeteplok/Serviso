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
