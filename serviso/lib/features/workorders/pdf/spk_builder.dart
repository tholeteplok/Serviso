import 'dart:async';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/work_order.dart';

/// Input untuk membangun dokumen SPK (Surat Perintah Kerja).
///
/// Berbeda dari [ReceiptInput] (struk pembayaran, dicetak SETELAH WO selesai &
/// dibayar) — SPK dicetak SEGERA setelah WO dibuat, sebelum pengerjaan dimulai,
/// dan isinya adalah instruksi kerja + tanda tangan, bukan rincian pembayaran.
class SpkInput {
  const SpkInput({
    required this.shopName,
    this.shopAddress,
    this.shopPhone,
    required this.spkNumber,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    required this.targetLabel,
    required this.targetValue,
    required this.complaintLabel,
    this.complaint,
    this.technicianName,
    this.items = const [],
    required this.printedBy,
    required this.printedAt,
  });

  final String shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String spkNumber;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String targetLabel;
  final String targetValue;
  final String complaintLabel;
  final String? complaint;
  final String? technicianName;
  final List<WoItem> items;
  final String printedBy;
  final DateTime printedAt;
}

class SpkBuildResult {
  const SpkBuildResult({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _dateId(DateTime v) => '${_pad(v.day)}/${_pad(v.month)}/${v.year}';

String _dateTimeId(DateTime v) =>
    '${_dateId(v)} ${_pad(v.hour)}:${_pad(v.minute)}';

String _rupiah(double value) {
  final s = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

pw.Document _buildDocument(SpkInput input) {
  final pdf = pw.Document();
  final bold = pw.Font.helveticaBold();
  final regular = pw.Font.helvetica();

  pw.Widget fieldBox(String label, String value, {int minLines = 1}) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1, color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(
            value.isEmpty ? '-' : value,
            style: pw.TextStyle(font: regular, fontSize: 11),
          ),
          if (minLines > 1) pw.SizedBox(height: 16 * (minLines - 1)),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header toko
            pw.Text(input.shopName,
                style: pw.TextStyle(font: bold, fontSize: 15)),
            if (input.shopAddress != null)
              pw.Text(input.shopAddress!,
                  style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey700)),
            if (input.shopPhone != null)
              pw.Text(input.shopPhone!,
                  style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.5, color: PdfColors.black),
            pw.SizedBox(height: 6),

            pw.Center(
              child: pw.Text('SURAT PERINTAH KERJA',
                  style: pw.TextStyle(font: bold, fontSize: 13)),
            ),
            pw.SizedBox(height: 12),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('No: ${input.spkNumber}',
                    style: pw.TextStyle(font: bold, fontSize: 10)),
                pw.Text(_dateId(input.createdAt),
                    style: pw.TextStyle(font: regular, fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 12),

            fieldBox(
              'PELANGGAN',
              [input.customerName, input.customerPhone]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(' - '),
            ),
            fieldBox(input.targetLabel.toUpperCase(), input.targetValue),
            fieldBox(input.complaintLabel.toUpperCase(), input.complaint ?? '',
                minLines: 3),

            if (input.items.isNotEmpty) ...[
              pw.Text('ITEM AWAL',
                  style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Deskripsi',
                            style: pw.TextStyle(font: bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Qty',
                            style: pw.TextStyle(font: bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Estimasi',
                            style: pw.TextStyle(font: bold, fontSize: 8)),
                      ),
                    ],
                  ),
                  for (final item in input.items)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            item.kind == WoItemKind.part
                                ? (item.partName ?? item.description ?? 'Part')
                                : (item.description ?? 'Jasa'),
                            style: pw.TextStyle(font: regular, fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${item.qty}',
                              style: pw.TextStyle(font: regular, fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(_rupiah(item.qty * item.unitPrice - item.discount),
                              style: pw.TextStyle(font: regular, fontSize: 8)),
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Estimasi awal - dapat berubah saat pengerjaan.',
                  style: pw.TextStyle(
                      font: regular, fontSize: 7, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
            ],

            pw.SizedBox(height: 4),
            fieldBox('TEKNISI', input.technicianName ?? 'Belum ditentukan'),

            pw.Spacer(),

            // Tanda tangan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 40),
                    pw.Container(width: 110, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Pelanggan',
                        style: pw.TextStyle(font: regular, fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 40),
                    pw.Container(width: 110, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Teknisi / Admin',
                        style: pw.TextStyle(font: regular, fontSize: 9)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Dicetak oleh ${input.printedBy} - ${_dateTimeId(input.printedAt)}',
              style: pw.TextStyle(font: regular, fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        );
      },
    ),
  );
  return pdf;
}

Future<SpkBuildResult> buildSpkPdf(SpkInput input) async {
  final pdf = _buildDocument(input);
  final bytes = await pdf.save();
  return SpkBuildResult(
    bytes: bytes,
    filename: 'SPK-${input.spkNumber}.pdf',
  );
}
