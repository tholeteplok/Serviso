import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../auth/models/profile.dart';
import '../models/payment.dart';
import '../models/work_order.dart';
import 'receipt_builder.dart';

ReceiptInput _buildInput({
  required WorkOrder order,
  required Profile profile,
  required String printedBy,
}) {
  return ReceiptInput(
    shopName: profile.shopName ?? 'Bengkel',
    shopAddress: null,
    shopPhone: null,
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
}) async {
  final result = await buildReceiptPdf(
    _buildInput(order: order, profile: profile, printedBy: printedBy),
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
}) async {
  final result = await buildReceiptPdf(
    _buildInput(order: order, profile: profile, printedBy: printedBy),
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
}) {
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Bagikan PDF'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              shareReceipt(
                order: order,
                profile: profile,
                printedBy: printedBy,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Pratinjau'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              previewReceipt(
                order: order,
                profile: profile,
                printedBy: printedBy,
              );
            },
          ),
        ],
      ),
    ),
  );
}

