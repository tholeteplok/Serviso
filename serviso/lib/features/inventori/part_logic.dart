double previewAdjustStock(double currentStock, double signedDelta) {
  return currentStock + signedDelta;
}

bool canAdjustStock(double currentStock, double signedDelta) {
  return previewAdjustStock(currentStock, signedDelta) >= 0;
}

const String insufficientStockMessage =
    'Stok tidak cukup untuk koreksi ini';

const String emptyReasonMessage = 'Alasan koreksi wajib diisi';
