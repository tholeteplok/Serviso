class DailySummaryRow {
  final DateTime date;
  final double revenue;
  final int woDoneCount;
  final int directSaleCount;
  final double partsOutQty;

  const DailySummaryRow({
    required this.date,
    required this.revenue,
    required this.woDoneCount,
    this.directSaleCount = 0,
    required this.partsOutQty,
  });

  int get totalTransactions => woDoneCount + directSaleCount;

  factory DailySummaryRow.fromMap(Map<String, dynamic> map) {
    return DailySummaryRow(
      date: DateTime.parse(map['date'].toString()),
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      woDoneCount: (map['wo_done_count'] as num?)?.toInt() ?? 0,
      directSaleCount: (map['direct_sale_count'] as num?)?.toInt() ?? 0,
      partsOutQty: (map['parts_out_qty'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'revenue': revenue,
      'wo_done_count': woDoneCount,
      'direct_sale_count': directSaleCount,
      'parts_out_qty': partsOutQty,
    };
  }
}

class TransactionRow {
  final String id;
  final String number;
  final String type; // 'wo' | 'pl'
  final double amount;
  final String? payMethod;
  final DateTime transactedAt;
  final String? plateNo;
  final String? customerName;
  final int itemCount;

  const TransactionRow({
    required this.id,
    required this.number,
    required this.type,
    required this.amount,
    this.payMethod,
    required this.transactedAt,
    this.plateNo,
    this.customerName,
    required this.itemCount,
  });

  bool get isWo => type == 'wo';
  bool get isPl => type == 'pl';

  factory TransactionRow.fromMap(Map<String, dynamic> map) {
    return TransactionRow(
      id: map['id'] as String? ?? '',
      number: map['number'] as String? ?? map['wo_number'] as String? ?? map['sale_number'] as String? ?? '',
      type: map['type'] as String? ?? 'wo',
      amount: (map['amount'] as num?)?.toDouble() ?? (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      payMethod: map['pay_method'] as String?,
      transactedAt: map['transacted_at'] != null
          ? DateTime.parse(map['transacted_at'].toString())
          : map['paid_at'] != null
              ? DateTime.parse(map['paid_at'].toString())
              : map['completed_at'] != null
                  ? DateTime.parse(map['completed_at'].toString())
                  : DateTime.now(),
      plateNo: map['plate_no'] as String?,
      customerName: map['customer_name'] as String?,
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopPartRow {
  final DateTime monthStart;
  final String partId;
  final String name;
  final double qtyOut;
  final double revenue;

  const TopPartRow({
    required this.monthStart,
    required this.partId,
    required this.name,
    required this.qtyOut,
    required this.revenue,
  });

  factory TopPartRow.fromMap(Map<String, dynamic> map) {
    return TopPartRow(
      monthStart: DateTime.parse(map['month_start'].toString()),
      partId: map['part_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Suku Cadang',
      qtyOut: (map['qty_out'] as num?)?.toDouble() ?? 0.0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month_start': monthStart.toIso8601String().substring(0, 10),
      'part_id': partId,
      'name': name,
      'qty_out': qtyOut,
      'revenue': revenue,
    };
  }
}

class QueueCounts {
  final int waiting;
  final int inProgress;
  final int done;

  const QueueCounts({
    required this.waiting,
    required this.inProgress,
    required this.done,
  });
}

class DashboardSummary {
  final double todayRevenue;
  final int activeWoCount;
  final int lowStockCount;
  final List<DailySummaryRow> last7Days;

  const DashboardSummary({
    required this.todayRevenue,
    required this.activeWoCount,
    required this.lowStockCount,
    required this.last7Days,
  });
}

class OwnerFinancialSummary {
  final double totalRevenue;
  final double totalCogs;
  final double totalUnpaidDebt;

  const OwnerFinancialSummary({
    required this.totalRevenue,
    required this.totalCogs,
    required this.totalUnpaidDebt,
  });

  double get netProfit => totalRevenue - totalCogs;
}

class DistributorDebtItem {
  final String movementId;
  final String partId;
  final String partName;
  final String distributor;
  final double qty;
  final double purchasePrice;
  final double totalDebt;
  final double totalPaid;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String debtStatus;

  const DistributorDebtItem({
    required this.movementId,
    required this.partId,
    required this.partName,
    required this.distributor,
    required this.qty,
    required this.purchasePrice,
    required this.totalDebt,
    this.totalPaid = 0,
    required this.createdAt,
    this.dueDate,
    required this.debtStatus,
  });

  /// Sisa hutang yang belum dibayar
  double get remaining => totalDebt - totalPaid;

  /// Apakah sudah lunas (total bayar >= total hutang)
  bool get isSettled => remaining <= 0;

  /// Progress pembayaran (0.0 - 1.0)
  double get paymentProgress =>
      totalDebt > 0 ? (totalPaid / totalDebt).clamp(0.0, 1.0) : 0.0;
}

/// Record of a single debt payment (partial or full).
class DebtPaymentRecord {
  final String id;
  final String movementId;
  final double amount;
  final String? payMethod;
  final String? note;
  final DateTime createdAt;

  const DebtPaymentRecord({
    required this.id,
    required this.movementId,
    required this.amount,
    this.payMethod,
    this.note,
    required this.createdAt,
  });

  factory DebtPaymentRecord.fromMap(Map<String, dynamic> map) {
    return DebtPaymentRecord(
      id: map['id'] as String? ?? '',
      movementId: map['movement_id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      payMethod: map['pay_method'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'movement_id': movementId,
      'amount': amount,
      'pay_method': payMethod,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProfitBreakdownRow {
  final DateTime date;
  final double revenue;
  final double cogs;
  final double profit;

  const ProfitBreakdownRow({
    required this.date,
    required this.revenue,
    required this.cogs,
    double? profit,
  }) : profit = profit ?? (revenue - cogs);

  factory ProfitBreakdownRow.fromMap(Map<String, dynamic> map) {
    final rev = (map['revenue'] as num?)?.toDouble() ?? 0.0;
    final c = (map['cogs'] as num?)?.toDouble() ?? 0.0;
    return ProfitBreakdownRow(
      date: DateTime.parse(map['date'].toString()),
      revenue: rev,
      cogs: c,
      profit: (map['profit'] as num?)?.toDouble() ?? rev - c,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'revenue': revenue,
      'cogs': cogs,
      'profit': profit,
    };
  }
}

class WoDoneRow {
  final String id;
  final String woNumber;
  final String? plateNo;
  final String? customerName;
  final DateTime completedAt;
  final double paidAmount;
  final int itemCount;
  final String? status;
  final String? payMethod;

  const WoDoneRow({
    required this.id,
    required this.woNumber,
    this.plateNo,
    this.customerName,
    required this.completedAt,
    required this.paidAmount,
    this.itemCount = 0,
    this.status,
    this.payMethod,
  });

  factory WoDoneRow.fromMap(Map<String, dynamic> map) {
    final vehicles = map['vehicles'] as Map?;
    final plate = vehicles?['plate_no'] as String?;
    String? custName;
    if (vehicles != null) {
      final cust = vehicles['customers'];
      if (cust is Map) custName = cust['name'] as String?;
    }
    final woItems = map['wo_items'];
    int count = 0;
    if (woItems is List) count = woItems.length;
    if (map['item_count'] != null) {
      count = (map['item_count'] as num).toInt();
    }
    return WoDoneRow(
      id: map['id'] as String? ?? '',
      woNumber: map['wo_number'] as String? ?? '',
      plateNo: plate ?? map['plate_no'] as String?,
      customerName: custName ?? map['customer_name'] as String?,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'].toString())
          : DateTime.parse(map['created_at'].toString()),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      itemCount: count,
      status: map['status'] as String?,
      payMethod: map['pay_method'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wo_number': woNumber,
      'plate_no': plateNo,
      'customer_name': customerName,
      'completed_at': completedAt.toIso8601String(),
      'paid_amount': paidAmount,
      'item_count': itemCount,
      'status': status,
      'pay_method': payMethod,
    };
  }
}

class PartSoldDetailRow {
  final String partId;
  final String name;
  final double qtyOut;
  final double revenue;
  final DateTime monthStart;

  const PartSoldDetailRow({
    required this.partId,
    required this.name,
    required this.qtyOut,
    required this.revenue,
    required this.monthStart,
  });

  factory PartSoldDetailRow.fromMap(Map<String, dynamic> map) {
    return PartSoldDetailRow(
      partId: map['part_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Suku Cadang',
      qtyOut: (map['qty_out'] as num?)?.toDouble() ?? 0.0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      monthStart: map['month_start'] != null
          ? DateTime.parse(map['month_start'].toString())
          : map['period_start'] != null
              ? DateTime.parse(map['period_start'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'part_id': partId,
      'name': name,
      'qty_out': qtyOut,
      'revenue': revenue,
      'month_start': monthStart.toIso8601String().substring(0, 10),
    };
  }
}

class DailyRevenueByMethodRow {
  final DateTime date;
  final String? payMethod;
  final double revenue;
  final int woCount;

  const DailyRevenueByMethodRow({
    required this.date,
    this.payMethod,
    required this.revenue,
    required this.woCount,
  });

  factory DailyRevenueByMethodRow.fromMap(Map<String, dynamic> map) {
    return DailyRevenueByMethodRow(
      date: DateTime.parse(map['date'].toString()),
      payMethod: map['pay_method'] as String?,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      woCount: (map['wo_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'pay_method': payMethod,
      'revenue': revenue,
      'wo_count': woCount,
    };
  }
}

class HppRow {
  final String woId;
  final String woNumber;
  final DateTime completedAt;
  final double totalCogs;
  final int itemCount;

  const HppRow({
    required this.woId,
    required this.woNumber,
    required this.completedAt,
    required this.totalCogs,
    required this.itemCount,
  });

  factory HppRow.fromMap(Map<String, dynamic> map) {
    return HppRow(
      woId: map['wo_id'] as String? ?? map['work_order_id'] as String? ?? '',
      woNumber: map['wo_number'] as String? ?? '',
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'].toString())
          : DateTime.now(),
      totalCogs: (map['total_cogs'] as num?)?.toDouble() ??
          (map['cogs'] as num?)?.toDouble() ??
          0.0,
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wo_id': woId,
      'wo_number': woNumber,
      'completed_at': completedAt.toIso8601String(),
      'total_cogs': totalCogs,
      'item_count': itemCount,
    };
  }
}
