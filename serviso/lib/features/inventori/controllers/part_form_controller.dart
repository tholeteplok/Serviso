import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/part.dart';
import 'part_list_controller.dart';
import 'part_providers.dart';

class PartFormController
    extends AutoDisposeFamilyAsyncNotifier<void, Part?> {
  @override
  Future<void> build(Part? arg) async {}

  Future<void> submit({
    required String name,
    String? code,
    String? unit,
    required int minStock,
    double? costPrice,
    double? sellPrice,
  }) async {
    final repo = ref.read(partRepositoryProvider);
    final input = PartInput(
      id: arg?.id,
      name: name,
      code: code,
      unit: unit,
      minStock: minStock,
      costPrice: costPrice,
      sellPrice: sellPrice,
    );
    state = const AsyncLoading();
    try {
      if (arg == null) {
        await repo.createPart(input);
      } else {
        await repo.updatePart(input);
      }
      ref.invalidate(partListControllerProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final partFormControllerProvider =
    AsyncNotifierProvider.autoDispose.family<PartFormController, void, Part?>(
  PartFormController.new,
);
