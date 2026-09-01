import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../laporan/controllers/report_controllers.dart';
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
    double initialStock = 0,
    String? distributor,
    String paymentType = 'tunai',
    DateTime? dueDate,
  }) async {
    final effectiveInitialStock = initialStock > 0 ? initialStock : 0.0;
    final effectiveDistributor =
        effectiveInitialStock > 0 ? distributor?.trim() : null;
    final effectivePaymentType =
        effectiveInitialStock > 0 ? paymentType : 'tunai';
    final effectiveDueDate =
        (effectiveInitialStock > 0 && effectivePaymentType == 'hutang')
            ? dueDate
            : null;

    final repo = ref.read(partRepositoryProvider);
    final input = PartInput(
      id: arg?.id,
      name: name.trim(),
      code: code?.trim().isEmpty == true ? null : code?.trim(),
      unit: unit?.trim().isEmpty == true ? 'pcs' : unit?.trim(),
      minStock: minStock < 0 ? 0 : minStock,
      costPrice: costPrice,
      sellPrice: sellPrice,
      initialStock: effectiveInitialStock,
      distributor: effectiveDistributor?.isEmpty == true ? null : effectiveDistributor,
      paymentType: effectivePaymentType,
      dueDate: effectiveDueDate,
    );
    state = const AsyncLoading();
    try {
      if (arg == null) {
        await repo.createPart(input);
      } else {
        await repo.updatePart(input);
      }
      ref.invalidate(partListControllerProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (effectiveInitialStock > 0) {
        ref.invalidate(distributorDebtsProvider);
        ref.invalidate(ownerFinancialSummaryProvider);
      }
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
