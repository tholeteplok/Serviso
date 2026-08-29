import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/theme/app_icons.dart';
import 'package:serviso/core/widgets/pastel_pop_bottom_bar.dart';

void main() {
  testWidgets('PastelPopBottomBar renders items and responds to tap', (tester) async {
    int tappedIndex = -1;

    final items = [
      PastelPopBottomBarItem(
        icon: AppIcons.home,
        selectedIcon: AppIcons.homeFill,
        label: 'Beranda',
      ),
      PastelPopBottomBarItem(
        icon: AppIcons.queue,
        selectedIcon: AppIcons.queueFill,
        label: 'Antrian',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PastelPopBottomBar(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
            items: items,
          ),
        ),
      ),
    );

    // Active item shows label
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.byIcon(AppIcons.homeFill), findsOneWidget);
    expect(find.byIcon(AppIcons.queue), findsOneWidget);

    // Tap second item
    await tester.tap(find.byIcon(AppIcons.queue));
    await tester.pump();

    expect(tappedIndex, 1);
  });
}
