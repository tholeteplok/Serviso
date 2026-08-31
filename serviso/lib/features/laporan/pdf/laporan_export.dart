import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/report_models.dart';

// -----------------------------------------------------------------------------
// Helpers umum
// -----------------------------------------------------------------------------

String _rupiah(num value) {
  final formatted = value
      .abs()
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return value < 0 ? '-Rp$formatted' : 'Rp$formatted';
}

String _dateId(DateTime value) {
  String pad(int n) => n.toString().padLeft(2, '0');
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}, '
      '${pad(value.hour)}.${pad(value.minute)}';
}

String _dateOnly(DateTime value) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${value.year}-${pad(value.month)}-${pad(value.day)}';
}

String _formatQty(num qty) {
  final d = qty.toDouble();
  final isInt = d == d.roundToDouble();
  return isInt ? d.round().toString() : d.toString();
}

String _csvEscape(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _payMethodLabel(String? value) {
  switch (value) {
    case 'transfer':
      return 'Transfer';
    case 'qris':
      return 'QRIS';
    case 'cash':
      return 'Tunai';
    default:
      return 'Belum Bayar';
  }
}

String _fileName(String prefix, DateTime date, String ext) {
  return 'laporan_${prefix}_${_dateOnly(date)}.$ext';
}

// Header PDF — sesuai spec: title, periodLabel, exportedAt
pw.Widget _pdfHeader(
  String title,
  String periodLabel,
  DateTime exportedAt,
) {
  final mono = pw.Font.courier();
  final sansBold = pw.Font.helveticaBold();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(font: sansBold, fontSize: 14),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        periodLabel,
        style: pw.TextStyle(font: mono, fontSize: 8, color: PdfColors.grey700),
      ),
      pw.Text(
        'Diekspor: ${_dateId(exportedAt)}',
        style: pw.TextStyle(font: mono, fontSize: 7, color: PdfColors.grey600),
      ),
      pw.Divider(thickness: 1, color: PdfColors.grey400),
    ],
  );
}

pw.Widget _emptyState(pw.Font mono) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 24),
    child: pw.Text(
      'Tidak ada data pada periode ini',
      style: pw.TextStyle(
        font: mono,
        fontSize: 9,
        color: PdfColors.grey700,
      ),
    ),
  );
}

pw.Widget _footer(DateTime exportedAt, pw.Font mono) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Text(
      'Diekspor oleh Serviso \u2022 ${_dateId(exportedAt)}',
      style: pw.TextStyle(font: mono, fontSize: 7, color: PdfColors.grey600),
    ),
  );
}

pw.Widget _summaryRow(
  String label,
  String value,
  pw.Font mono,
  pw.Font monoBold,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: mono, fontSize: 8)),
        pw.Text(value, style: pw.TextStyle(font: monoBold, fontSize: 8)),
      ],
    ),
  );
}

pw.Widget _buildTable({
  required List<String> headers,
  required List<List<String>> data,
  required pw.Font mono,
  required pw.Font monoBold,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    headerStyle: pw.TextStyle(
      font: monoBold,
      fontSize: 7,
      color: PdfColors.white,
    ),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
    cellStyle: pw.TextStyle(font: mono, fontSize: 7),
    cellAlignment: pw.Alignment.centerLeft,
    headerAlignment: pw.Alignment.center,
    cellHeight: 18,
    headerHeight: 20,
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: null,
  );
}

// -----------------------------------------------------------------------------
// Generic share helpers
// -----------------------------------------------------------------------------

Future<void> sharePdfBytes(Uint8List bytes, String filename) async {
  if (bytes.isEmpty) {
    throw ArgumentError('PDF bytes kosong, tidak dapat dibagikan');
  }
  try {
    await Printing.sharePdf(bytes: bytes, filename: filename);
    return;
  } catch (_) {
    // fallback via temp file + share_plus
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: filename),
  );
}

Future<void> shareCsv(String csvContent, String filename) async {
  if (filename.isEmpty) {
    throw ArgumentError('filename tidak boleh kosong');
  }
  // Allow empty csv header-only, but not completely empty
  if (csvContent.isEmpty) {
    throw ArgumentError('CSV content kosong, tidak dapat dibagikan');
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(csvContent);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: filename),
  );
}

// -----------------------------------------------------------------------------
// OMSET — DailySummaryRow
// -----------------------------------------------------------------------------

Future<Uint8List> buildOmsetPdf({
  required List<DailySummaryRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final pdf = pw.Document();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();

  final totalRevenue = rows.fold<double>(0, (s, r) => s + r.revenue);
  final avgRevenue = rows.isEmpty ? 0.0 : totalRevenue / rows.length;
  final maxRevenue = rows.isEmpty
      ? 0.0
      : rows.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
  final totalWo = rows.fold<int>(0, (s, r) => s + r.woDoneCount);
  final totalQty = rows.fold<double>(0, (s, r) => s + r.partsOutQty);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 18,
        marginRight: 18,
        marginTop: 16,
        marginBottom: 16,
      ),
      footer: (ctx) => _footer(exportedAt, mono),
      build: (ctx) => [
        _pdfHeader('$shopName — Laporan Omset', periodLabel, exportedAt),
        pw.SizedBox(height: 8),
        // Ringkasan
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColors.grey100,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Ringkasan',
                style: pw.TextStyle(font: monoBold, fontSize: 9),
              ),
              pw.SizedBox(height: 4),
              _summaryRow('Total Revenue', _rupiah(totalRevenue), mono, monoBold),
              _summaryRow('Rata-rata / hari', _rupiah(avgRevenue), mono, monoBold),
              _summaryRow('Maksimum harian', _rupiah(maxRevenue), mono, monoBold),
              _summaryRow('Total WO Selesai', '$totalWo WO', mono, monoBold),
              _summaryRow(
                'Total Qty Part',
                '${_formatQty(totalQty)} pcs',
                mono,
                monoBold,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        if (rows.isEmpty)
          _emptyState(mono)
        else
          _buildTable(
            headers: const ['Tanggal', 'Revenue', 'WO Selesai', 'Qty Part'],
            data: rows
                .map(
                  (r) => [
                    _dateOnly(r.date),
                    _rupiah(r.revenue),
                    r.woDoneCount.toString(),
                    _formatQty(r.partsOutQty),
                  ],
                )
                .toList(),
            mono: mono,
            monoBold: monoBold,
          ),
      ],
    ),
  );

  return pdf.save();
}

String buildOmsetCsv(List<DailySummaryRow> rows) {
  final sb = StringBuffer();
  sb.writeln('Tanggal,Revenue,WO Selesai,Qty Part');
  for (final r in rows) {
    sb.writeln(
      '${_dateOnly(r.date)},${r.revenue.toStringAsFixed(0)},${r.woDoneCount},${r.partsOutQty.toStringAsFixed(0)}',
    );
  }
  return sb.toString();
}

Future<void> exportOmsetPdf({
  required List<DailySummaryRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final bytes = await buildOmsetPdf(
    rows: rows,
    periodLabel: periodLabel,
    exportedAt: exportedAt,
    shopName: shopName,
  );
  final filename = _fileName('omset', exportedAt, 'pdf');
  await sharePdfBytes(bytes, filename);
}

Future<void> exportOmsetCsv({
  required List<DailySummaryRow> rows,
  required DateTime exportedAt,
}) async {
  final csv = buildOmsetCsv(rows);
  final filename = _fileName('omset', exportedAt, 'csv');
  await shareCsv(csv, filename);
}

// -----------------------------------------------------------------------------
// WO DONE — WoDoneRow
// -----------------------------------------------------------------------------

Future<Uint8List> buildWoDonePdf({
  required List<WoDoneRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final pdf = pw.Document();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();

  final totalPaid = rows.fold<double>(0, (s, r) => s + r.paidAmount);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape.copyWith(
        marginLeft: 16,
        marginRight: 16,
        marginTop: 16,
        marginBottom: 16,
      ),
      footer: (ctx) => _footer(exportedAt, mono),
      build: (ctx) => [
        _pdfHeader('$shopName — WO Selesai', periodLabel, exportedAt),
        pw.SizedBox(height: 6),
        pw.Text(
          'Total WO: ${rows.length}  •  Total Paid: ${_rupiah(totalPaid)}',
          style: pw.TextStyle(font: mono, fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        if (rows.isEmpty)
          _emptyState(mono)
        else
          _buildTable(
            headers: const [
              'No',
              'WO Number',
              'Plat',
              'Pelanggan',
              'Tgl Selesai',
              'Paid Amount',
              'Metode',
              'Items',
            ],
            data: rows.asMap().entries.map((e) {
              final i = e.key + 1;
              final r = e.value;
              return [
                i.toString(),
                r.woNumber,
                r.plateNo ?? '-',
                r.customerName ?? '-',
                _dateOnly(r.completedAt),
                _rupiah(r.paidAmount),
                _payMethodLabel(r.payMethod),
                r.itemCount.toString(),
              ];
            }).toList(),
            mono: mono,
            monoBold: monoBold,
          ),
      ],
    ),
  );

  return pdf.save();
}

String buildWoDoneCsv(List<WoDoneRow> rows) {
  final sb = StringBuffer();
  sb.writeln('No,WO Number,Plat,Pelanggan,Tgl Selesai,Paid Amount,Metode,Items');
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    sb.writeln(
      '${i + 1},${_csvEscape(r.woNumber)},${_csvEscape(r.plateNo ?? '-')},'
      '${_csvEscape(r.customerName ?? '-')},${_dateOnly(r.completedAt)},'
      '${r.paidAmount.toStringAsFixed(0)},${_csvEscape(_payMethodLabel(r.payMethod))},${r.itemCount}',
    );
  }
  return sb.toString();
}

Future<void> exportWoDonePdf({
  required List<WoDoneRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final bytes = await buildWoDonePdf(
    rows: rows,
    periodLabel: periodLabel,
    exportedAt: exportedAt,
    shopName: shopName,
  );
  final filename = _fileName('wo_selesai', exportedAt, 'pdf');
  await sharePdfBytes(bytes, filename);
}

Future<void> exportWoDoneCsv({
  required List<WoDoneRow> rows,
  required DateTime exportedAt,
}) async {
  final csv = buildWoDoneCsv(rows);
  final filename = _fileName('wo_selesai', exportedAt, 'csv');
  await shareCsv(csv, filename);
}

// -----------------------------------------------------------------------------
// PART SOLD — PartSoldDetailRow
// -----------------------------------------------------------------------------

Future<Uint8List> buildPartSoldPdf({
  required List<PartSoldDetailRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final pdf = pw.Document();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();

  final totalQty = rows.fold<double>(0, (s, r) => s + r.qtyOut);
  final totalRev = rows.fold<double>(0, (s, r) => s + r.revenue);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 18,
        marginRight: 18,
        marginTop: 16,
        marginBottom: 16,
      ),
      footer: (ctx) => _footer(exportedAt, mono),
      build: (ctx) => [
        _pdfHeader('$shopName — Part Terjual', periodLabel, exportedAt),
        pw.SizedBox(height: 6),
        pw.Text(
          'Total Qty: ${_formatQty(totalQty)} pcs  •  Total Revenue: ${_rupiah(totalRev)}',
          style: pw.TextStyle(font: mono, fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        if (rows.isEmpty)
          _emptyState(mono)
        else
          _buildTable(
            headers: const [
              'No',
              'Nama Part',
              'Qty Terjual',
              'Revenue',
              'Avg Price',
            ],
            data: rows.asMap().entries.map((e) {
              final i = e.key + 1;
              final r = e.value;
              final avg = r.qtyOut == 0 ? 0 : r.revenue / r.qtyOut;
              return [
                i.toString(),
                r.name,
                _formatQty(r.qtyOut),
                _rupiah(r.revenue),
                _rupiah(avg),
              ];
            }).toList(),
            mono: mono,
            monoBold: monoBold,
          ),
      ],
    ),
  );

  return pdf.save();
}

String buildPartSoldCsv(List<PartSoldDetailRow> rows) {
  final sb = StringBuffer();
  sb.writeln('No,Nama Part,Qty Terjual,Revenue,Avg Price');
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final avg = r.qtyOut == 0 ? 0 : r.revenue / r.qtyOut;
    sb.writeln(
      '${i + 1},${_csvEscape(r.name)},${_formatQty(r.qtyOut)},'
      '${r.revenue.toStringAsFixed(0)},${avg.toStringAsFixed(0)}',
    );
  }
  return sb.toString();
}

Future<void> exportPartSoldPdf({
  required List<PartSoldDetailRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final bytes = await buildPartSoldPdf(
    rows: rows,
    periodLabel: periodLabel,
    exportedAt: exportedAt,
    shopName: shopName,
  );
  final filename = _fileName('part_terjual', exportedAt, 'pdf');
  await sharePdfBytes(bytes, filename);
}

Future<void> exportPartSoldCsv({
  required List<PartSoldDetailRow> rows,
  required DateTime exportedAt,
}) async {
  final csv = buildPartSoldCsv(rows);
  final filename = _fileName('part_terjual', exportedAt, 'csv');
  await shareCsv(csv, filename);
}

// -----------------------------------------------------------------------------
// PROFIT — ProfitBreakdownRow (owner-only)
// -----------------------------------------------------------------------------

Future<Uint8List> buildProfitPdf({
  required List<ProfitBreakdownRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final pdf = pw.Document();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();

  final totalOmset = rows.fold<double>(0, (s, r) => s + r.revenue);
  final totalHpp = rows.fold<double>(0, (s, r) => s + r.cogs);
  final totalLaba = rows.fold<double>(0, (s, r) => s + r.profit);
  final avgMargin = totalOmset == 0 ? 0 : totalLaba / totalOmset * 100;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 18,
        marginRight: 18,
        marginTop: 16,
        marginBottom: 16,
      ),
      footer: (ctx) => _footer(exportedAt, mono),
      build: (ctx) => [
        _pdfHeader('$shopName — Laba Rugi', periodLabel, exportedAt),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColors.grey100,
          ),
          child: pw.Column(
            children: [
              _summaryRow('Total Omset', _rupiah(totalOmset), mono, monoBold),
              _summaryRow('Total HPP', _rupiah(totalHpp), mono, monoBold),
              _summaryRow('Total Laba', _rupiah(totalLaba), mono, monoBold),
              _summaryRow(
                'Margin Rata-rata',
                '${avgMargin.toStringAsFixed(1)}%',
                mono,
                monoBold,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        if (rows.isEmpty)
          _emptyState(mono)
        else
          _buildTable(
            headers: const ['Tanggal', 'Omset', 'HPP', 'Laba', 'Margin%'],
            data: rows.map((r) {
              final margin = r.revenue == 0 ? 0.0 : r.profit / r.revenue * 100;
              return [
                _dateOnly(r.date),
                _rupiah(r.revenue),
                _rupiah(r.cogs),
                _rupiah(r.profit),
                '${margin.toStringAsFixed(1)}%',
              ];
            }).toList(),
            mono: mono,
            monoBold: monoBold,
          ),
      ],
    ),
  );

  return pdf.save();
}

String buildProfitCsv(List<ProfitBreakdownRow> rows) {
  final sb = StringBuffer();
  sb.writeln('Tanggal,Omset,HPP,Laba,Margin%');
  for (final r in rows) {
    final margin = r.revenue == 0 ? 0.0 : r.profit / r.revenue * 100;
    sb.writeln(
      '${_dateOnly(r.date)},${r.revenue.toStringAsFixed(0)},'
      '${r.cogs.toStringAsFixed(0)},${r.profit.toStringAsFixed(0)},'
      '${margin.toStringAsFixed(1)}%',
    );
  }
  return sb.toString();
}

Future<void> exportProfitPdf({
  required List<ProfitBreakdownRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final bytes = await buildProfitPdf(
    rows: rows,
    periodLabel: periodLabel,
    exportedAt: exportedAt,
    shopName: shopName,
  );
  final filename = _fileName('laba', exportedAt, 'pdf');
  await sharePdfBytes(bytes, filename);
}

Future<void> exportProfitCsv({
  required List<ProfitBreakdownRow> rows,
  required DateTime exportedAt,
}) async {
  final csv = buildProfitCsv(rows);
  final filename = _fileName('laba', exportedAt, 'csv');
  await shareCsv(csv, filename);
}

// -----------------------------------------------------------------------------
// HPP — HppRow (owner-only)
// -----------------------------------------------------------------------------

Future<Uint8List> buildHppPdf({
  required List<HppRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final pdf = pw.Document();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();

  final totalHpp = rows.fold<double>(0, (s, r) => s + r.totalCogs);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 18,
        marginRight: 18,
        marginTop: 16,
        marginBottom: 16,
      ),
      footer: (ctx) => _footer(exportedAt, mono),
      build: (ctx) => [
        _pdfHeader('$shopName — HPP / Modal', periodLabel, exportedAt),
        pw.SizedBox(height: 6),
        pw.Text(
          'Total HPP: ${_rupiah(totalHpp)}  •  Jumlah WO: ${rows.length}',
          style: pw.TextStyle(font: mono, fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        if (rows.isEmpty)
          _emptyState(mono)
        else
          _buildTable(
            headers: const ['WO Number', 'Tgl', 'Total HPP', 'Item Count'],
            data: rows
                .map(
                  (r) => [
                    r.woNumber,
                    _dateOnly(r.completedAt),
                    _rupiah(r.totalCogs),
                    r.itemCount.toString(),
                  ],
                )
                .toList(),
            mono: mono,
            monoBold: monoBold,
          ),
      ],
    ),
  );

  return pdf.save();
}

String buildHppCsv(List<HppRow> rows) {
  final sb = StringBuffer();
  sb.writeln('WO Number,Tgl,Total HPP,Item Count');
  for (final r in rows) {
    sb.writeln(
      '${_csvEscape(r.woNumber)},${_dateOnly(r.completedAt)},'
      '${r.totalCogs.toStringAsFixed(0)},${r.itemCount}',
    );
  }
  return sb.toString();
}

Future<void> exportHppPdf({
  required List<HppRow> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final bytes = await buildHppPdf(
    rows: rows,
    periodLabel: periodLabel,
    exportedAt: exportedAt,
    shopName: shopName,
  );
  final filename = _fileName('hpp', exportedAt, 'pdf');
  await sharePdfBytes(bytes, filename);
}

Future<void> exportHppCsv({
  required List<HppRow> rows,
  required DateTime exportedAt,
}) async {
  final csv = buildHppCsv(rows);
  final filename = _fileName('hpp', exportedAt, 'csv');
  await shareCsv(csv, filename);
}

// -----------------------------------------------------------------------------
// DEBT — DistributorDebtItem (owner-only)
// -----------------------------------------------------------------------------

Future<Uint8List> buildDebtPdf({
  required List<DistributorDebtItem> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final pdf = pw.Document();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();

  final totalDebt = rows.fold<double>(0, (s, r) => s + r.totalDebt);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape.copyWith(
        marginLeft: 16,
        marginRight: 16,
        marginTop: 16,
        marginBottom: 16,
      ),
      footer: (ctx) => _footer(exportedAt, mono),
      build: (ctx) => [
        _pdfHeader('$shopName — Hutang Distributor', periodLabel, exportedAt),
        pw.SizedBox(height: 6),
        pw.Text(
          'Total Hutang: ${_rupiah(totalDebt)}  •  Jumlah Item: ${rows.length}',
          style: pw.TextStyle(font: mono, fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        if (rows.isEmpty)
          _emptyState(mono)
        else
          _buildTable(
            headers: const [
              'Distributor',
              'Part',
              'Qty',
              'Hutang',
              'Jatuh Tempo',
              'Status',
            ],
            data: rows
                .map(
                  (r) => [
                    r.distributor,
                    r.partName,
                    _formatQty(r.qty),
                    _rupiah(r.totalDebt),
                    r.dueDate != null ? _dateOnly(r.dueDate!) : '-',
                    r.debtStatus,
                  ],
                )
                .toList(),
            mono: mono,
            monoBold: monoBold,
          ),
      ],
    ),
  );

  return pdf.save();
}

String buildDebtCsv(List<DistributorDebtItem> rows) {
  final sb = StringBuffer();
  sb.writeln('Distributor,Part,Qty,Hutang,Jatuh Tempo,Status');
  for (final r in rows) {
    sb.writeln(
      '${_csvEscape(r.distributor)},${_csvEscape(r.partName)},'
      '${_formatQty(r.qty)},${r.totalDebt.toStringAsFixed(0)},'
      '${r.dueDate != null ? _dateOnly(r.dueDate!) : ''},'
      '${_csvEscape(r.debtStatus)}',
    );
  }
  return sb.toString();
}

Future<void> exportDebtPdf({
  required List<DistributorDebtItem> rows,
  required String periodLabel,
  required DateTime exportedAt,
  String shopName = 'Serviso',
}) async {
  final bytes = await buildDebtPdf(
    rows: rows,
    periodLabel: periodLabel,
    exportedAt: exportedAt,
    shopName: shopName,
  );
  final filename = _fileName('hutang', exportedAt, 'pdf');
  await sharePdfBytes(bytes, filename);
}

Future<void> exportDebtCsv({
  required List<DistributorDebtItem> rows,
  required DateTime exportedAt,
}) async {
  final csv = buildDebtCsv(rows);
  final filename = _fileName('hutang', exportedAt, 'csv');
  await shareCsv(csv, filename);
}
