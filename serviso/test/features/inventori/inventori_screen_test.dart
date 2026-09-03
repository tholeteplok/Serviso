// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/theme/app_theme.dart';
import 'package:serviso/core/widgets/thick_bottom_border_button.dart';
import 'package:serviso/features/auth/controllers/session_controller.dart';
import 'package:serviso/features/inventori/controllers/part_detail_controller.dart';
import 'package:serviso/features/inventori/controllers/part_providers.dart';
import 'package:serviso/features/inventori/data/fakes.dart';
import 'package:serviso/features/inventori/models/part.dart';
import 'package:serviso/features/inventori/screens/inventori_screen.dart';
import 'package:serviso/features/inventori/screens/part_detail_screen.dart';

Widget _pumpList({
  required FakePartRepository parts,
  bool isAdmin = false,
}) {
  final container = ProviderContainer(
    overrides: [
      partRepositoryProvider.overrideWithValue(parts),
      isAdminProvider.overrideWithValue(isAdmin),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const InventoriScreen(),
    ),
  );
}

class _Harness {
  _Harness({required this.widget, required this.container});

  final Widget widget;
  final ProviderContainer container;
}

Future<_Harness> _pumpDetail({
  required FakePartRepository parts,
  required String partId,
  bool isAdmin = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      partRepositoryProvider.overrideWithValue(parts),
      isAdminProvider.overrideWithValue(isAdmin),
    ],
  );
  addTearDown(container.dispose);
  final widget = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: PartDetailScreen(partId: partId),
    ),
  );
  return _Harness(widget: widget, container: container);
}

void main() {
  group('InventoriScreen', () {
    testWidgets('empty state menampilkan ajakan Tambah Suku Cadang',
        (tester) async {
      await tester.pumpWidget(_pumpList(parts: FakePartRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada suku cadang'), findsOneWidget);
      expect(find.widgetWithText(ThickBottomBorderButton, 'Tambah Suku Cadang'),
          findsOneWidget);
    });

    testWidgets('render daftar dengan badge Stok Menipis saat stok rendah',
        (tester) async {
      final fake = FakePartRepository();
      final low = await fake.createPart(
        PartInput(name: 'Oli', code: 'P001', minStock: 5),
      );
      await fake.stockIn(low.id, 2);
      await fake.createPart(PartInput(name: 'Busi', code: 'P002'));

      await tester.pumpWidget(_pumpList(parts: fake));
      await tester.pumpAndSettle();

      expect(find.text('Oli'), findsOneWidget);
      expect(find.text('Busi'), findsOneWidget);
      expect(find.text('Stok Menipis'), findsWidgets);
    });

    testWidgets('filter chip Stok Menipis memanggil repository filter',
        (tester) async {
      final fake = FakePartRepository();
      final low = await fake.createPart(
        PartInput(name: 'Oli', minStock: 5),
      );
      await fake.stockIn(low.id, 1);
      final busi = await fake.createPart(PartInput(name: 'Busi'));
      await fake.stockIn(busi.id, 20);

      await tester.pumpWidget(_pumpList(parts: fake));
      await tester.pumpAndSettle();
      final textFinder = find.text('Stok Menipis');
      final segmentFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(GestureDetector),
      );
      await tester.tap(segmentFinder.first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Oli'), findsOneWidget);
      expect(find.text('Busi'), findsNothing);
    });
  });

  group('PartDetailScreen', () {
    testWidgets('history kosong menampilkan empty state kartu stok',
        (tester) async {
      final fake = FakePartRepository();
      final part = await fake.createPart(PartInput(name: 'Filter'));

      final h = await _pumpDetail(parts: fake, partId: part.id);
      await tester.pumpWidget(h.widget);
      await tester.pumpAndSettle();
      await h.container.read(partDetailControllerProvider(part.id).future);
      await tester.pumpAndSettle();

      expect(find.text('Filter'), findsOneWidget);
      expect(
        find.text('Belum ada pergerakan stok', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan riwayat kartu stok', (tester) async {
      final fake = FakePartRepository();
      final part = await fake.createPart(PartInput(name: 'Oli'));
      await fake.stockIn(part.id, 10, note: 'pembelian');

      final h = await _pumpDetail(parts: fake, partId: part.id);
      await tester.pumpWidget(h.widget);
      await tester.pumpAndSettle();
      await h.container.read(partDetailControllerProvider(part.id).future);
      await tester.pumpAndSettle();

      expect(find.text('Kartu Stok', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Pembelian • pembelian', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('kasir melihat Stok Masuk tapi tidak Koreksi Stok',
        (tester) async {
      final fake = FakePartRepository();
      final part = await fake.createPart(PartInput(name: 'Oli'));

      final h = await _pumpDetail(
        parts: fake,
        partId: part.id,
        isAdmin: false,
      );
      await tester.pumpWidget(h.widget);
      await tester.pumpAndSettle();
      await h.container.read(partDetailControllerProvider(part.id).future);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ThickBottomBorderButton, 'Stok Masuk'), findsWidgets);
      expect(find.text('Koreksi Stok'), findsNothing);
    });

    testWidgets('admin melihat tombol Koreksi Stok', (tester) async {
      final fake = FakePartRepository();
      final part = await fake.createPart(PartInput(name: 'Oli'));

      final h = await _pumpDetail(
        parts: fake,
        partId: part.id,
        isAdmin: true,
      );
      await tester.pumpWidget(h.widget);
      await tester.pumpAndSettle();
      await h.container.read(partDetailControllerProvider(part.id).future);
      await tester.pumpAndSettle();

      expect(
        find.text('Koreksi Stok', skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}
