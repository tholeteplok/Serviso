import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/neo_bottom_sheet.dart';
import '../../auth/models/profile.dart';
import '../../settings/models/app_settings.dart';
import '../models/payment.dart';
import '../models/work_order.dart';
import 'receipt_builder.dart';

ReceiptInput _buildInput({
  required WorkOrder order,
  required Profile profile,
  required String printedBy,
  AppSettings? settings,
}) {
  return ReceiptInput(
    shopName: settings?.shopName.isNotEmpty == true
        ? settings!.shopName
        : (profile.shopName ?? 'Bengkel'),
    shopAddress: settings?.address,
    shopPhone: settings?.phone,
    receiptNotes: settings?.receiptNotes,
    woNumber: order.woNumber,
    plate: order.plateNo ?? '—',
    vehicleDesc: order.vehicleDesc,
    customerName: order.customerName,
    items: order.items,
    total: order.total,
    payMethod: order.payMethod?.label ?? 'Tunai',
    paidAmount: order.paidAmount,
    printedBy: printedBy,
    printedAt: DateTime.now(),
  );
}

Future<void> shareReceipt({
  required WorkOrder order,
  required Profile profile,
  required String printedBy,
  AppSettings? settings,
}) async {
  final result = await buildReceiptPdf(
    _buildInput(
      order: order,
      profile: profile,
      printedBy: printedBy,
      settings: settings,
    ),
  );
  final file = await _saveTempPdf(result);
  await Printing.sharePdf(
    bytes: await file.readAsBytes(),
    filename: result.filename,
  );
}

Future<void> previewReceipt({
  required WorkOrder order,
  required Profile profile,
  required String printedBy,
  AppSettings? settings,
}) async {
  final result = await buildReceiptPdf(
    _buildInput(
      order: order,
      profile: profile,
      printedBy: printedBy,
      settings: settings,
    ),
  );
  final file = await _saveTempPdf(result);
  await Printing.layoutPdf(
    name: result.filename,
    onLayout: (format) async => Uint8List.fromList(await file.readAsBytes()),
  );
}

Future<File> _saveTempPdf(ReceiptBuildResult result) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${result.filename}');
  await file.writeAsBytes(result.bytes);
  return file;
}

void showReceiptOptions({
  required BuildContext context,
  required WorkOrder order,
  required Profile profile,
  required String printedBy,
  AppSettings? settings,
}) {
  showNeoBottomSheet(
    context: context,
    title: 'Opsi Struk Pembayaran',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(AppIcons.share, color: AppColors.ink900),
          title: const Text('Bagikan PDF'),
          trailing: Icon(AppIcons.caretRight, size: 16, color: AppColors.textSecondary),
          onTap: () {
            Navigator.of(context).pop();
            shareReceipt(
              order: order,
              profile: profile,
              printedBy: printedBy,
              settings: settings,
            );
          },
        ),
        const Divider(height: 1, color: AppColors.borderHairline),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(AppIcons.eye, color: AppColors.ink900),
          title: const Text('Pratinjau'),
          trailing: Icon(AppIcons.caretRight, size: 16, color: AppColors.textSecondary),
          onTap: () {
            Navigator.of(context).pop();
            previewReceipt(
              order: order,
              profile: profile,
              printedBy: printedBy,
              settings: settings,
            );
          },
        ),
      ],
    ),
  );
}

