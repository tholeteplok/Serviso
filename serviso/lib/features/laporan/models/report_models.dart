class DailySummaryRow {
  final DateTime date;
  final double revenue;
  final int woDoneCount;
  final double partsOutQty;

  const DailySummaryRow({
    required this.date,
    required this.revenue,
    required this.woDoneCount,
    required this.partsOutQty,
  });

  factory DailySummaryRow.fromMap(Map<String, dynamic> map) {
    return DailySummaryRow(
      date: DateTime.parse(map['date'].toString()),
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      woDoneCount: (map['wo_done_count'] as num?)?.toInt() ?? 0,
      partsOutQty: (map['parts_out_qty'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'revenue': revenue,
      'wo_done_count': woDoneCount,
      'parts_out_qty': partsOutQty,
    };
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
