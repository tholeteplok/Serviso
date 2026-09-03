import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serviso/core/theme/app_icons.dart';
import 'package:serviso/core/widgets/thick_bottom_border_button.dart';
import 'package:serviso/features/customers/controllers/customer_providers.dart';
import 'package:serviso/features/customers/data/fakes.dart';
import 'package:serviso/features/direct_sales/data/direct_sale_repository.dart';
import 'package:serviso/features/direct_sales/models/direct_sale.dart';
import 'package:serviso/features/direct_sales/screens/direct_sale_screen.dart';
import 'package:serviso/features/inventori/controllers/part_providers.dart';
import 'package:serviso/features/inventori/data/fakes.dart';
import 'package:serviso/features/inventori/models/part.dart';
import 'package:serviso/features/workorders/models/payment.dart';
import 'package:serviso/features/workorders/models/work_order.dart';
import 'package:serviso/features/workorders/pdf/receipt_builder.dart';

void main() {
  group('DirectSale Models & Repository Tests', () {
    test('DirectSaleResult fromMap parses id and sale_number properly', () {
      final res = DirectSaleResult.fromMap({
        'id': 'uuid-1234',
        'sale_number': 'DS-260902-001',
      });
      expect(res.id, 'uuid-1234');
      expect(res.saleNumber, 'DS-260902-001');
    });

    test('FakeDirectSaleRepository generates sequence DS-yymmdd-001 format', () async {
      final repo = FakeDirectSaleRepository();
      const draft = DirectSaleDraft(
        items: [
          DirectSaleItemInput(
            kind: WoItemKind.part,
            qty: 2,
            unitPrice: 2500,
            description: 'Kuaci Rebo 10g',
          ),
        ],
        payMethod: PaymentMethod.cash,
        paidAmount: 5000,
      );

      final result1 = await repo.checkout(draft);
      expect(result1.saleNumber, matches(r'^DS-\d{6}-001$'));

      final result2 = await repo.checkout(draft);
      expect(result2.saleNumber, matches(r'^DS-\d{6}-002$'));
    });
  });

  group('DirectSale Receipt PDF Tests', () {
    test('buildReceiptPdf produces valid PDF with DS-yymmdd-001 saleNumber and No. Transaksi label', () async {
      final input = ReceiptInput(
        shopName: 'Bengkel Uji Serviso',
        shopAddress: 'jl. Merdeka 2',
        shopPhone: '08123456789',
        receiptNotes: 'Terima kasih telah berkunjung.',
        woNumber: 'DS-260902-001',
        plate: 'Penjualan Langsung',
        items: const [
          WoItem(
            id: 'p1',
            kind: WoItemKind.part,
            description: 'Kuaci Rebo 10g',
            qty: 7,
            unitPrice: 2500,
          ),
        ],
        total: 17500,
        payMethod: 'Tunai',
        paidAmount: 17500,
        printedBy: 'teplok',
        printedAt: DateTime.now(),
      );

      final result = await buildReceiptPdf(input);
      expect(result.bytes.isNotEmpty, isTrue);
      expect(result.pageCount, 1);
      expect(result.filename, contains('struk_DS-260902-001'));
    });
  });

  group('DirectSaleScreen E-Commerce Retail Tests', () {
    Widget pumpScreen({
      required FakePartRepository parts,
      required FakeDirectSaleRepository directSales,
      FakeCustomerRepository? customers,
    }) {
      return ProviderScope(
        overrides: [
          partRepositoryProvider.overrideWithValue(parts),
          directSaleRepositoryProvider.overrideWithValue(directSales),
          customerRepositoryProvider
              .overrideWithValue(customers ?? FakeCustomerRepository()),
        ],
        child: const MaterialApp(
          home: DirectSaleScreen(),
        ),
      );
    }

    testWidgets('katalog merender nama, kode part, stok status, dan tombol Tambah',
        (tester) async {
      final partRepo = FakePartRepository();
      await partRepo.createPart(const PartInput(
        name: 'Oli Yamalube 1L',
        code: 'OLI-01',
        sellPrice: 45000,
        initialStock: 10,
      ));

      await tester.pumpWidget(pumpScreen(
        parts: partRepo,
        directSales: FakeDirectSaleRepository(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Oli Yamalube 1L'), findsOneWidget);
      expect(find.text('OLI-01'), findsOneWidget);
      expect(find.text('Stok 10'), findsOneWidget);
      expect(find.widgetWithText(ThickBottomBorderButton, 'Tambah'),
          findsOneWidget);
      // Bottom cart bar is hidden when cart is empty
      expect(find.text('Total (0 item)'), findsNothing);
    });

    testWidgets(
        'menekan Tambah memunculkan in-card stepper dan sticky bottom cart bar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final partRepo = FakePartRepository();
      await partRepo.createPart(const PartInput(
        name: 'Busi Champion',
        code: 'BSI-01',
        sellPrice: 20000,
        initialStock: 5,
      ));

      await tester.pumpWidget(pumpScreen(
        parts: partRepo,
        directSales: FakeDirectSaleRepository(),
      ));
      await tester.pumpAndSettle();

      // Tap Tambah
      await tester
          .tap(find.widgetWithText(ThickBottomBorderButton, 'Tambah'));
      await tester.pumpAndSettle();

      // Card now has stepper with 1
      expect(find.text('1'), findsWidgets);
      // Bottom bar appears
      expect(find.text('Total (1 item)'), findsOneWidget);
      expect(find.text('Rp20.000'), findsWidgets);

      // Increment qty
      await tester.tap(find.byIcon(AppIcons.add).last);
      await tester.pumpAndSettle();
      expect(find.text('Total (2 item)'), findsOneWidget);
      expect(find.text('Rp40.000'), findsWidgets);

      // Decrement qty
      await tester.tap(find.byIcon(AppIcons.minus).first);
      await tester.pumpAndSettle();
      expect(find.text('Total (1 item)'), findsOneWidget);

      // Decrement to 0 removes from cart and restores Tambah button
      await tester.tap(find.byIcon(AppIcons.minus).first);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ThickBottomBorderButton, 'Tambah'),
          findsOneWidget);
      expect(find.text('Total (0 item)'), findsNothing);
    });

    testWidgets(
        'checkout mengosongkan keranjang (anti-double charge) dan menampilkan dialog Transaksi Baru',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final partRepo = FakePartRepository();
      await partRepo.createPart(const PartInput(
        name: 'Kampas Rem Depan',
        code: 'KMP-01',
        sellPrice: 35000,
        initialStock: 8,
      ));

      final directSaleRepo = FakeDirectSaleRepository();

      await tester.pumpWidget(pumpScreen(
        parts: partRepo,
        directSales: directSaleRepo,
      ));
      await tester.pumpAndSettle();

      // Tambah item ke keranjang
      await tester
          .tap(find.widgetWithText(ThickBottomBorderButton, 'Tambah'));
      await tester.pumpAndSettle();

      // Buka modal sheet keranjang
      await tester
          .tap(find.widgetWithText(ThickBottomBorderButton, 'Keranjang'));
      await tester.pumpAndSettle();

      expect(find.text('Keranjang Belanja'), findsOneWidget);
      expect(find.text('Pelanggan'), findsOneWidget);

      // Tap Selesaikan & Bayar
      await tester.tap(find.widgetWithText(
          ThickBottomBorderButton, 'Selesaikan & Bayar (Rp35.000)'));
      await tester.pumpAndSettle();

      // Verifikasi dialog sukses muncul
      expect(find.text('Transaksi Berhasil!'), findsOneWidget);
      expect(find.textContaining('No. Nota: DS-'), findsOneWidget);
      expect(find.widgetWithText(ThickBottomBorderButton, 'Transaksi Baru'),
          findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);

      // Tap Transaksi Baru
      await tester.tap(
          find.widgetWithText(ThickBottomBorderButton, 'Transaksi Baru'));
      await tester.pumpAndSettle();

      // Dialog sukses tertutup, keranjang bersih (0 item), siap transaksi baru
      expect(find.text('Transaksi Berhasil!'), findsNothing);
      expect(find.text('Total (0 item)'), findsNothing);
      expect(find.widgetWithText(ThickBottomBorderButton, 'Tambah'),
          findsOneWidget);
    });

    testWidgets(
        'pencarian memfilter katalog berdasarkan nama/kode dan tombol clear mereset filter',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final partRepo = FakePartRepository();
      await partRepo.createPart(const PartInput(
        name: 'Oli Yamalube 1L',
        code: 'OLI-01',
        sellPrice: 45000,
        initialStock: 10,
      ));
      await partRepo.createPart(const PartInput(
        name: 'Busi Champion',
        code: 'BSI-01',
        sellPrice: 20000,
        initialStock: 5,
      ));

      await tester.pumpWidget(pumpScreen(
        parts: partRepo,
        directSales: FakeDirectSaleRepository(),
      ));
      await tester.pumpAndSettle();

      // Keduanya tampil
      expect(find.text('Oli Yamalube 1L'), findsOneWidget);
      expect(find.text('Busi Champion'), findsOneWidget);

      // Cari 'busi'
      await tester.enterText(find.byType(TextField).first, 'busi');
      await tester.pumpAndSettle();

      expect(find.text('Oli Yamalube 1L'), findsNothing);
      expect(find.text('Busi Champion'), findsOneWidget);

      // Cari berdasarkan kode 'OLI'
      await tester.enterText(find.byType(TextField).first, 'OLI');
      await tester.pumpAndSettle();

      expect(find.text('Oli Yamalube 1L'), findsOneWidget);
      expect(find.text('Busi Champion'), findsNothing);

      // Tekan tombol clear (X)
      expect(find.byTooltip('Tutup'), findsOneWidget);
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      // Keduanya tampil kembali
      expect(find.text('Oli Yamalube 1L'), findsOneWidget);
      expect(find.text('Busi Champion'), findsOneWidget);
    });

    testWidgets('tombol barcode scanner di search bar membuka modal scanner',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final partRepo = FakePartRepository();
      await partRepo.createPart(const PartInput(
        name: 'Oli Yamalube 1L',
        code: 'OLI-01',
        sellPrice: 45000,
        initialStock: 10,
      ));

      await tester.pumpWidget(pumpScreen(
        parts: partRepo,
        directSales: FakeDirectSaleRepository(),
      ));
      await tester.pumpAndSettle();

      // Tap tombol barcode scanner
      expect(find.byTooltip('Scan Barcode'), findsOneWidget);
      await tester.tap(find.byTooltip('Scan Barcode'));
      await tester.pumpAndSettle();

      // Modal scanner terbuka
      expect(find.text('Pindai Barcode / QR'), findsOneWidget);
    });
  });
}
