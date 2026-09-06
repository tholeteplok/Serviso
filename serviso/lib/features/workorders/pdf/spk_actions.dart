import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../models/work_order.dart';
import 'spk_builder.dart';

Future<File> _saveTempPdf(SpkBuildResult result) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${result.filename}');
  await file.writeAsBytes(result.bytes);
  return file;
}

Future<void> shareSpk(SpkInput input) async {
  final result = await buildSpkPdf(input);
  final file = await _saveTempPdf(result);
  await Printing.sharePdf(
    bytes: await file.readAsBytes(),
    filename: result.filename,
  );
}

Future<void> previewSpk(SpkInput input) async {
  final result = await buildSpkPdf(input);
  final file = await _saveTempPdf(result);
  await Printing.layoutPdf(
    name: result.filename,
    onLayout: (format) async => Uint8List.fromList(await file.readAsBytes()),
  );
}

/// Ditampilkan segera setelah Work Order berhasil dibuat — tawarkan cetak SPK
/// sebagai opsi, bukan langkah wajib (kasir yang buru-buru bisa lewati).
Future<void> showSpkPrompt({
  required BuildContext context,
  required SpkInput input,
}) async {
  await showNeoBottomSheet(
    context: context,
    title: 'Work Order Dibuat',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No. ${input.spkNumber} — cetak Surat Perintah Kerja (SPK) untuk teknisi/pelanggan?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(AppIcons.share, color: AppColors.ink900),
          title: const Text('Bagikan PDF SPK'),
          trailing: Icon(AppIcons.caretRight, size: 16, color: AppColors.textSecondary),
          onTap: () {
            Navigator.of(context).pop();
            shareSpk(input);
          },
        ),
        const Divider(height: 1, color: AppColors.borderHairline),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(AppIcons.print, color: AppColors.ink900),
          title: const Text('Cetak / Pratinjau'),
          trailing: Icon(AppIcons.caretRight, size: 16, color: AppColors.textSecondary),
          onTap: () {
            Navigator.of(context).pop();
            previewSpk(input);
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Lewati'),
          ),
        ),
      ],
    ),
  );
}

SpkInput buildSpkInputFromWorkOrder({
  required WorkOrder order,
  required String shopName,
  String? shopAddress,
  String? shopPhone,
  String? customerPhone,
  required String targetLabel,
  required String complaintLabel,
  String? technicianName,
  required String printedBy,
}) {
  final targetValue = order.vehicleId != null
      ? [order.plateNo, order.vehicleDesc]
          .where((e) => e != null && e.isNotEmpty)
          .join(' - ')
      : (order.serviceLabel ?? '-');

  return SpkInput(
    shopName: shopName,
    shopAddress: shopAddress,
    shopPhone: shopPhone,
    spkNumber: order.woNumber,
    createdAt: order.createdAt,
    customerName: order.customerName,
    customerPhone: customerPhone,
    targetLabel: targetLabel,
    targetValue: targetValue.isEmpty ? '-' : targetValue,
    complaintLabel: complaintLabel,
    complaint: order.complaint,
    technicianName: technicianName,
    items: order.items,
    printedBy: printedBy,
    printedAt: DateTime.now(),
  );
}
