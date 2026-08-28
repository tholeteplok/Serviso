import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/admin/widgets/json_diff_viewer.dart';

void main() {
  testWidgets('JsonDiffViewer highlights added, deleted, and modified keys',
      (tester) async {
    final oldData = {'name': 'Oli Lama', 'price': 50000};
    final newData = {'name': 'Oli Baru', 'stock': 10};

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: JsonDiffViewer(
            oldData: oldData,
            newData: newData,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('name:'), findsNWidgets(2)); // old & new
    expect(find.textContaining('Oli Lama'), findsOneWidget);
    expect(find.textContaining('Oli Baru'), findsOneWidget);
    expect(find.textContaining('price:'), findsOneWidget);
    expect(find.textContaining('stock:'), findsOneWidget);
  });
}
