import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/theme/app_icons.dart';
import 'package:serviso/core/widgets/pastel_pop_bottom_bar.dart';

void main() {
  testWidgets('PastelPopBottomBar renders 5-slot items and responds to taps', (tester) async {
    int tappedIndex = -1;
    bool centerTapped = false;

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
      PastelPopBottomBarItem(
        icon: AppIcons.inventory,
        selectedIcon: AppIcons.inventoryFill,
        label: 'Inventori',
      ),
      PastelPopBottomBarItem(
        icon: AppIcons.report,
        selectedIcon: AppIcons.reportFill,
        label: 'Laporan',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PastelPopBottomBar(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
            onCenterActionTap: () => centerTapped = true,
            items: items,
          ),
        ),
      ),
    );

    // Active item shows selected icon, other items show inactive icon
    expect(find.byIcon(AppIcons.homeFill), findsOneWidget);
    expect(find.byIcon(AppIcons.queue), findsOneWidget);
    expect(find.byIcon(AppIcons.inventory), findsOneWidget);
    expect(find.byIcon(AppIcons.report), findsOneWidget);

    // Center circular [+] button is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap second item (Antrian)
    await tester.tap(find.byIcon(AppIcons.queue));
    await tester.pump();
    expect(tappedIndex, 1);

    // Tap fourth item (Laporan)
    await tester.tap(find.byIcon(AppIcons.report));
    await tester.pump();
    expect(tappedIndex, 3);

    // Tap center button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(centerTapped, true);
  });
}
