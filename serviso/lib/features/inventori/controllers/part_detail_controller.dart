import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository_exception.dart';
import '../models/part.dart';
import '../models/part_movement.dart';
import 'part_list_controller.dart';
import 'part_providers.dart';

class PartDetailData {
  const PartDetailData({
    required this.part,
    required this.movements,
  });

  final Part part;
  final List<PartMovement> movements;
}

class PartDetailController
    extends AutoDisposeFamilyAsyncNotifier<PartDetailData, String> {
  @override
  Future<PartDetailData> build(String arg) async {
    final repo = ref.watch(partRepositoryProvider);
    final part = await repo.getById(arg);
    if (part == null) {
      throw const RepositoryException('Suku cadang tidak ditemukan');
    }
    final movements = await repo.movements(arg);
    return PartDetailData(part: part, movements: movements);
  }

  Future<void> stockIn(double qty, {String? note}) async {
    final repo = ref.read(partRepositoryProvider);
    await repo.stockIn(arg, qty, note: note);
    ref.invalidateSelf();
    ref.invalidate(partListControllerProvider);
  }

  Future<void> adjustStock(double signedDelta, String reason) async {
    final repo = ref.read(partRepositoryProvider);
    await repo.adjustStock(arg, signedDelta, reason);
    ref.invalidateSelf();
    ref.invalidate(partListControllerProvider);
  }

  Future<void> deletePart() async {
    final repo = ref.read(partRepositoryProvider);
    await repo.deletePart(arg);
    ref.invalidate(partListControllerProvider);
  }

  Future<void> reload() async => ref.invalidateSelf();
}

final partDetailControllerProvider =
    AsyncNotifierProvider.autoDispose.family<PartDetailController,
        PartDetailData, String>(
  PartDetailController.new,
);
