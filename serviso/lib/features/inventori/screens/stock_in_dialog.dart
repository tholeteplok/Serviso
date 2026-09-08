import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/part.dart';
import 'stock_in_screen.dart';

export 'stock_in_screen.dart';

/// Convenience helper that navigates to [StockInScreen] for recording incoming stock.
Future<void> showStockInDialog(
  BuildContext context,
  WidgetRef ref,
  String partId, {
  Part? initialPart,
}) async {
  await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => StockInScreen(
        partId: partId,
        initialPart: initialPart,
      ),
    ),
  );
}
