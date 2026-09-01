double previewAdjustStock(double currentStock, double signedDelta) {
  return currentStock + signedDelta;
}

bool canAdjustStock(double currentStock, double signedDelta) {
  if (signedDelta == 0) return false;
  return previewAdjustStock(currentStock, signedDelta) >= 0;
}

const String insufficientStockMessage =
    'Stok tidak cukup untuk koreksi ini';

const String emptyReasonMessage = 'Alasan koreksi wajib diisi';
