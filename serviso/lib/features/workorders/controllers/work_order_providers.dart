import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/session_controller.dart';
import '../../auth/models/profile.dart';
import '../data/fakes.dart';
import '../models/work_order.dart';
import '../data/work_order_repository.dart';

final workOrderRepositoryProvider = Provider<WorkOrderRepository>((ref) {
  return SupabaseWorkOrderRepository(ref.watch(supabaseClientProvider));
});

final fakeWorkOrderRepositoryProvider = Provider<FakeWorkOrderRepository>((ref) {
  return FakeWorkOrderRepository();
});

final boardControllerProvider =
    StreamProvider.autoDispose<List<WorkOrder>>((ref) {
  return ref.watch(workOrderRepositoryProvider).watchBoard();
});

final todayFilterProvider = StateProvider<bool>((ref) => true);

final techniciansProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(workOrderRepositoryProvider).listTechnicians();
});
