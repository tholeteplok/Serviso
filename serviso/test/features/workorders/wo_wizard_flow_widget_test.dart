import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/features/customers/controllers/customer_providers.dart';
import 'package:serviso/features/customers/data/fakes.dart';
import 'package:serviso/features/customers/models/vehicle.dart';
import 'package:serviso/features/inventori/controllers/part_providers.dart';
import 'package:serviso/features/inventori/data/fakes.dart';
import 'package:serviso/features/workorders/controllers/work_order_providers.dart';
import 'package:serviso/features/workorders/data/fakes.dart';
import 'package:serviso/features/workorders/screens/wo_wizard_screen.dart';

void main() {
  late FakeVehicleRepository vehicleRepo;
  late FakeCustomerRepository customerRepo;
  late FakeWorkOrderRepository woRepo;
  late FakePartRepository partRepo;

  setUp(() {
    vehicleRepo = FakeVehicleRepository();
    customerRepo = FakeCustomerRepository();
    woRepo = FakeWorkOrderRepository();
    partRepo = FakePartRepository();
  });

  Widget createSubject({Vehicle? initialVehicle}) {
    return ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
        customerRepositoryProvider.overrideWithValue(customerRepo),
        workOrderRepositoryProvider.overrideWithValue(woRepo),
        partRepositoryProvider.overrideWithValue(partRepo),
        techniciansProvider.overrideWith((ref) => Future.value([])),
      ],
      child: MaterialApp(
        home: WoWizardScreen(initialVehicle: initialVehicle),
      ),
    );
  }

  testWidgets('WoWizardScreen: pilih kendaraan -> tombol Lanjut berpindah ke Step 1 -> isi keluhan -> Lanjut ke Step 2', (tester) async {
    final now = DateTime.now();
    final sampleVehicle = Vehicle(
      id: 'v1',
      customerId: 'c1',
      plateNo: 'B 1234 TEST',
      brand: 'Honda',
      model: 'Vario',
      createdAt: now,
    );

    await tester.pumpWidget(createSubject(initialVehicle: sampleVehicle));
    await tester.pumpAndSettle();

    // Verifikasi berada di Step 0: Pilih kendaraan
    expect(find.text('Pilih kendaraan'), findsOneWidget);
    expect(find.text('B 1234 TEST'), findsOneWidget);

    // Tekan tombol "Lanjut" di bawah
    final lanjutBtn = find.widgetWithText(FilledButton, 'Lanjut');
    expect(lanjutBtn, findsOneWidget);
    await tester.tap(lanjutBtn);
    await tester.pumpAndSettle();

    // Verifikasi BERHASIL berpindah ke Step 1: Detail work order
    expect(find.text('Detail work order'), findsOneWidget);
    expect(find.text('Keluhan'), findsOneWidget);

    // Isi keluhan
    final complaintInput = find.widgetWithText(TextFormField, 'Keluhan');
    await tester.enterText(complaintInput, 'Ganti oli berkala');
    await tester.pumpAndSettle();

    // Tekan "Lanjut" ke Step 2
    await tester.tap(lanjutBtn);
    await tester.pumpAndSettle();

    // Verifikasi BERHASIL berpindah ke Step 2: Item work order
    expect(find.text('Item work order'), findsOneWidget);
    expect(find.text('Buat Work Order'), findsOneWidget);
  });

  testWidgets('WoWizardScreen: belum pilih kendaraan -> tekan Lanjut muncul peringatan SnackBar', (tester) async {
    await tester.pumpWidget(createSubject(initialVehicle: null));
    await tester.pumpAndSettle();

    final lanjutBtn = find.widgetWithText(FilledButton, 'Lanjut');
    await tester.tap(lanjutBtn);
    await tester.pumpAndSettle();

    // Verifikasi SnackBar peringatan muncul
    expect(find.text('Pilih atau buat kendaraan dulu'), findsOneWidget);
    // Tetap di Step 0
    expect(find.text('Pilih kendaraan'), findsOneWidget);
  });
}
