import 'work_order.dart';

enum PaymentMethod { cash, transfer, qris }

extension PaymentMethodX on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.qris:
        return 'qris';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }

  static PaymentMethod fromValue(String? value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'qris':
        return PaymentMethod.qris;
      default:
        return PaymentMethod.cash;
    }
  }
}

class PaymentInfo {
  const PaymentInfo({
    required this.paidAmount,
    this.payMethod,
    this.paidAt,
  });

  final double paidAmount;
  final PaymentMethod? payMethod;
  final DateTime? paidAt;

  bool get isPaid => paidAt != null;

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      paidAmount: _parseNumeric(map['paid_amount']),
      payMethod: PaymentMethodX.fromValue(map['pay_method'] as String?),
      paidAt: map['paid_at'] == null
          ? null
          : DateTime.parse(map['paid_at'] as String),
    );
  }
}

class WoTotals {
  const WoTotals({
    required this.subtotal,
    required this.totalDiscount,
    required this.total,
  });

  final double subtotal;
  final double totalDiscount;
  final double total;

  static WoTotals calculate(List<WoItem> items) {
    var subtotal = 0.0;
    var totalDiscount = 0.0;
    for (final item in items) {
      subtotal += item.qty * item.unitPrice;
      totalDiscount += item.discount;
    }
    final rawTotal = subtotal - totalDiscount;
    return WoTotals(
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      total: rawTotal < 0 ? 0 : rawTotal,
    );
  }
}

class PaymentValidation {
  const PaymentValidation({required this.isValid, this.error});

  final bool isValid;
  final String? error;
}

PaymentValidation validatePaymentAmount(double amount, double total) {
  if (amount.isNaN || amount.isInfinite) {
    return const PaymentValidation(
      isValid: false,
      error: 'Nominal pembayaran tidak valid',
    );
  }
  if (amount < 0) {
    return const PaymentValidation(
      isValid: false,
      error: 'Nominal pembayaran tidak boleh negatif',
    );
  }
  if (total > 0 && amount < total) {
    return PaymentValidation(
      isValid: false,
      error: 'Nominal kurang dari total ${total.toStringAsFixed(0)}',
    );
  }
  if (total > 0 && amount > total * 1000) {
    return const PaymentValidation(
      isValid: false,
      error: 'Nominal pembayaran melebihi batas wajar',
    );
  }
  return const PaymentValidation(isValid: true);
}

double _parseNumeric(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
