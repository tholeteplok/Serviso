import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/models/wo_status.dart';
import 'package:serviso/core/theme/app_colors.dart';
import 'package:serviso/core/widgets/status_chip.dart';

void main() {
  group('pemetaan warna WoStatus', () {
    test('menunggu netral abu', () {
      expect(WoStatus.menunggu.accentColor, AppColors.inkMuted);
    });

    test('dikerjakan teal', () {
      expect(WoStatus.dikerjakan.accentColor, AppColors.teal);
    });

    test('selesai plum', () {
      expect(WoStatus.selesai.accentColor, AppColors.primary);
    });

    test('dibatalkan koral', () {
      expect(WoStatus.dibatalkan.accentColor, AppColors.action);
    });

    test('bg tint 12 persen dari warna aksen', () {
      for (final status in WoStatus.values) {
        expect(status.bgColor, status.accentColor.withValues(alpha: 0.12));
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
