import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle.dart';
import 'customer_providers.dart';

class VehicleFormArgs {
  const VehicleFormArgs({
    this.initial,
    required this.customerId,
  });

  final Vehicle? initial;
  final String customerId;
}

class VehicleFormController
    extends AutoDisposeFamilyAsyncNotifier<void, VehicleFormArgs> {
  @override
  Future<void> build(VehicleFormArgs arg) async {}

  Future<void> submit({
    required String plateNo,
    required String brand,
    required String model,
    required int? year,
    required String color,
  }) async {
    final repo = ref.read(vehicleRepositoryProvider);
    final input = VehicleInput(
      id: arg.initial?.id,
      customerId: arg.customerId,
      plateNo: plateNo,
      brand: brand,
      model: model,
      year: year,
      color: color,
    );
    state = const AsyncLoading();
    try {
      if (arg.initial == null) {
        await repo.create(input);
      } else {
        await repo.update(input);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final vehicleFormControllerProvider =
    AsyncNotifierProvider.autoDispose.family<VehicleFormController, void,
        VehicleFormArgs>(
  VehicleFormController.new,
);
