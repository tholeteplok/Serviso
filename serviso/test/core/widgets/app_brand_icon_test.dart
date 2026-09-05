import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/theme/app_colors.dart';
import 'package:serviso/core/widgets/app_brand_icon.dart';

void main() {
  testWidgets('AppBrandIcon renders with accent primary container and border', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBrandIcon(size: 64),
        ),
      ),
    );

    final containerFinder = find.byType(Container);
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration, isNotNull);
    expect(decoration!.color, AppColors.accentPrimary);
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
  });
}
