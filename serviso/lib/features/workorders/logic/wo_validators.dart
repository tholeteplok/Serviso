import '../models/work_order.dart';

abstract final class WoValidators {
  static String? validateComplaint(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Keluhan wajib diisi';
    }
    return null;
  }

  static String? validateItemDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Deskripsi wajib diisi';
    }
    return null;
  }

  static String? validateJasaPrice(double value) {
    if (value <= 0) return 'Harga harus lebih dari 0';
    return null;
  }

  static String? validatePartQty(double value) {
    if (value <= 0) return 'Jumlah part harus lebih dari 0';
    return null;
  }

  static bool isValidDraft(WorkOrderDraft draft) {
    if (draft.complaint == null || draft.complaint!.trim().isEmpty) {
      return false;
    }
    for (final item in draft.items) {
      if (item.qty <= 0) return false;
    }
    return true;
  }
}

abstract final class WoTotals {
  static double itemTotal(WoItem item) => item.lineTotal;

  static double grandTotal(List<WoItem> items) =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);
}
