import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/models/wo_status.dart';
import 'package:serviso/core/theme/app_colors.dart';
import 'package:serviso/core/widgets/status_chip.dart';

void main() {
  group('pemetaan warna WoStatus', () {
    test('menunggu oranye', () {
      expect(WoStatus.menunggu.accentColor, AppColors.statusWaiting);
    });

    test('dikerjakan biru', () {
      expect(WoStatus.dikerjakan.accentColor, AppColors.statusProgress);
    });

    test('selesai hijau', () {
      expect(WoStatus.selesai.accentColor, AppColors.statusDone);
    });

    test('dibatalkan koral', () {
      expect(WoStatus.dibatalkan.accentColor, AppColors.statusCancelled);
    });

    test('bg solid status color', () {
      for (final status in WoStatus.values) {
        expect(status.bgColor, status.accentColor);
      }
    });
  });

  testWidgets('menampilkan label status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: StatusChip(status: WoStatus.dikerjakan))),
      ),
    );

    expect(find.text('Dikerjakan'), findsOneWidget);
  });
}
