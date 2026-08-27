import 'dart:async';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/work_order.dart';

class ReceiptInput {
  const ReceiptInput({
    required this.shopName,
    this.shopAddress,
    this.shopPhone,
    required this.woNumber,
    required this.plate,
    this.vehicleDesc,
    this.customerName,
    required this.items,
    required this.total,
    required this.payMethod,
    required this.paidAmount,
    required this.printedBy,
    required this.printedAt,
  });

  final String shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String woNumber;
  final String plate;
  final String? vehicleDesc;
  final String? customerName;
  final List<WoItem> items;
  final double total;
  final String payMethod;
  final double paidAmount;
  final String printedBy;
  final DateTime printedAt;
}

class ReceiptBuildResult {
  const ReceiptBuildResult({
    required this.bytes,
    required this.pageCount,
    required this.filename,
  });

  final Uint8List bytes;
  final int pageCount;
  final String filename;
}

const double _kReceiptWidth = 226;
const double _kReceiptHeight = 424;

pw.Document _buildDocument(ReceiptInput input) {
  final pdf = pw.Document();
  final mono = pw.Font.courier();
  final monoBold = pw.Font.courierBold();
  final sansBold = pw.Font.helveticaBold();

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(
        _kReceiptWidth,
        _kReceiptHeight,
        marginLeft: 16,
        marginRight: 16,
        marginTop: 18,
        marginBottom: 18,
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            input.shopName,
            style: pw.TextStyle(
              font: sansBold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          if (input.shopAddress?.isNotEmpty == true)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                input.shopAddress!,
                style: pw.TextStyle(font: mono, fontSize: 8),
              ),
            ),
          if (input.shopPhone?.isNotEmpty == true)
            pw.Text(
              input.shopPhone!,
              style: pw.TextStyle(font: mono, fontSize: 8),
            ),
          pw.Divider(thickness: 1),
          _plateRow(input.plate, monoBold),
          pw.SizedBox(height: 6),
          _line('No. WO', input.woNumber, mono),
          if (input.vehicleDesc?.isNotEmpty == true)
            _line('Kendaraan', input.vehicleDesc!, mono),
          if (input.customerName?.isNotEmpty == true)
            _line('Pelanggan', input.customerName!, mono),
          pw.SizedBox(height: 8),
          pw.Text(
            'ITEM',
            style: pw.TextStyle(font: monoBold, fontSize: 9),
          ),
          pw.Divider(thickness: 0.5),
          ...input.items.map((item) => _itemRow(item, mono, monoBold)),
          pw.Divider(thickness: 1),
          _line('TOTAL', _rupiah(input.total), monoBold, align: true),
          pw.SizedBox(height: 6),
          _line('Metode', input.payMethod, mono),
          _line('Bayar', _rupiah(input.paidAmount), mono, align: true),
          if (shouldShowChange(input.payMethod, input.paidAmount, input.total))
            _line(
              'Kembali',
              _rupiah(input.paidAmount - input.total),
              mono,
              align: true,
            ),
          pw.Spacer(),
          pw.Divider(thickness: 0.5),
          pw.Text(
            buildReceiptFooter(input.printedBy, input.printedAt),
            style: pw.TextStyle(font: mono, fontSize: 7),
          ),
        ],
      ),
    ),
  );

  return pdf;
}

pw.Widget _plateRow(String plate, pw.Font bold) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 1.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    child: pw.Text(
      plate.toUpperCase(),
      style: pw.TextStyle(font: bold, fontSize: 12, letterSpacing: 1.5),
    ),
  );
}

pw.Widget _line(String label, String value, pw.Font font,
    {bool align = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: align
        ? pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text(value, style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          )
        : pw.Row(
            children: [
              pw.SizedBox(
                width: 64,
                child: pw.Text(
                  label,
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
              ),
            ],
          ),
  );
}

pw.Widget _itemRow(WoItem item, pw.Font mono, pw.Font monoBold) {
  final title = item.kind == WoItemKind.part
      ? (item.partName ?? item.description ?? 'Part')
      : (item.description ?? 'Jasa');
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: monoBold, fontSize: 9)),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${_formatQty(item.qty)} x ${_rupiah(item.unitPrice)}',
              style: pw.TextStyle(font: mono, fontSize: 8),
            ),
            pw.Text(
              _rupiah(item.lineTotal),
              style: pw.TextStyle(font: mono, fontSize: 8),
            ),
          ],
        ),
      ],
    ),
  );
}

String _rupiah(double value) {
  final formatted =
      value.abs().toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
  return value < 0 ? '-Rp$formatted' : 'Rp$formatted';
}

String _formatQty(double qty) {
  final isInt = qty == qty.roundToDouble();
  return isInt ? qty.round().toString() : qty.toString();
}

String _dateTimeId(DateTime value) {
  String pad(int n) => n.toString().padLeft(2, '0');
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}, '
      '${pad(value.hour)}.${pad(value.minute)}';
}

bool shouldShowChange(String payMethod, double paid, double total) {
  return payMethod == 'Tunai' && paid > total;
}

String buildReceiptFooter(String printedBy, DateTime printedAt) {
  return 'Dicetak oleh $printedBy · ${_dateTimeId(printedAt)}';
}

Future<ReceiptBuildResult> buildReceiptPdf(ReceiptInput input) async {
  final pdf = _buildDocument(input);
  final bytes = await pdf.save();
  final pageCount = pdf.document.pdfPageList.pages.length;
  final filename = 'struk_${input.woNumber}.pdf';
  return ReceiptBuildResult(
    bytes: bytes,
    pageCount: pageCount,
    filename: filename,
  );
}
