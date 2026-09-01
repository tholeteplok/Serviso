import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/inventori/controllers/part_providers.dart';
import 'package:serviso/features/inventori/data/fakes.dart';
import 'package:serviso/features/inventori/screens/part_form_screen.dart';

void main() {
  group('PartFormScreen Widget & Logic Tests', () {
    testWidgets('Admin view: renders basic info, price section, stepper, and buttons',
        (tester) async {
      final fakeRepo = FakePartRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            partRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PartFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Tambah Suku Cadang'),
        ),
        findsOneWidget,
      );
      expect(find.text('Informasi Dasar'), findsOneWidget);
      expect(find.text('Harga'), findsOneWidget);
      expect(find.text('Kuantitas'), findsOneWidget);
      expect(find.byKey(const Key('part_name_field')), findsOneWidget);
      expect(find.byKey(const Key('part_cost_field')), findsOneWidget);
      expect(find.byKey(const Key('part_sell_field')), findsOneWidget);

      // In initial state (quantity = 0), SectionCard "Pengadaan" is hidden
      expect(find.text('Pengadaan Stok Awal'), findsNothing);
    });

    testWidgets('Kasir view: hides price section and locks payment to cash',
        (tester) async {
      final fakeRepo = FakePartRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => false),
            partRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PartFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Harga diatur oleh pemilik. Suku cadang ditambahkan tanpa harga.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('part_cost_field')), findsNothing);
      expect(find.byKey(const Key('part_sell_field')), findsNothing);
    });

    testWidgets('Live Margin Calculation: calculates profit and warns on negative margin',
        (tester) async {
      final fakeRepo = FakePartRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            partRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PartFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter Cost = 40000, Sell = 50000 (Positive margin: Laba 10000, 20%)
      await tester.enterText(find.byKey(const Key('part_cost_field')), '40000');
      await tester.enterText(find.byKey(const Key('part_sell_field')), '50000');
      await tester.pumpAndSettle();

      expect(find.textContaining('Estimasi Laba: Rp10.000 / unit (Margin: 20.0%)'), findsOneWidget);

      // Enter Sell = 30000 (Negative margin: Rugi 10000)
      await tester.enterText(find.byKey(const Key('part_sell_field')), '30000');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Peringatan: Harga jual lebih rendah dari modal (Rugi Rp10.000 / unit)'),
        findsOneWidget,
      );
    });

    testWidgets('Validation: rejects empty name and negative numbers',
        (tester) async {
      final fakeRepo = FakePartRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            partRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PartFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll and Submit with empty name
      await tester.ensureVisible(find.byKey(const Key('submit_part_button')));
      await tester.tap(find.byKey(const Key('submit_part_button')));
      await tester.pumpAndSettle();

      expect(find.text('Nama suku cadang wajib diisi'), findsOneWidget);

      // Enter invalid negative cost and sell
      await tester.enterText(find.byKey(const Key('part_name_field')), 'Kampas Rem');
      await tester.enterText(find.byKey(const Key('part_cost_field')), '-10000');
      await tester.enterText(find.byKey(const Key('part_sell_field')), '-5000');
      await tester.enterText(find.byKey(const Key('part_min_stock_field')), '-2');

      await tester.ensureVisible(find.byKey(const Key('submit_part_button')));
      await tester.tap(find.byKey(const Key('submit_part_button')));
      await tester.pumpAndSettle();

      expect(find.text('Masukkan modal beli yang valid (>= 0)'), findsOneWidget);
      expect(find.text('Masukkan harga jual yang valid (>= 0)'), findsOneWidget);
      expect(find.text('Masukkan angka batas stok yang valid (>= 0)'), findsOneWidget);
    });

    testWidgets('Form submission: successfully creates part in repository',
        (tester) async {
      final fakeRepo = FakePartRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            partRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: PartFormScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('part_name_field')), 'Filter Udara Vario');
      await tester.enterText(find.byKey(const Key('part_cost_field')), '35000');
      await tester.enterText(find.byKey(const Key('part_sell_field')), '50000');
      await tester.enterText(find.byKey(const Key('part_min_stock_field')), '5');

      await tester.ensureVisible(find.byKey(const Key('submit_part_button')));
      await tester.tap(find.byKey(const Key('submit_part_button')));
      await tester.pumpAndSettle();

      final parts = await fakeRepo.list(search: 'Filter Udara');
      expect(parts.length, 1);
      expect(parts.first.name, 'Filter Udara Vario');
      expect(parts.first.costPrice, 35000);
      expect(parts.first.sellPrice, 50000);
      expect(parts.first.minStock, 5);
    });
  });
}
