import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/session_controller.dart';
import '../data/fakes.dart';
import '../data/part_repository.dart';

final partRepositoryProvider = Provider<PartRepository>((ref) {
  return SupabasePartRepository(ref.watch(supabaseClientProvider));
});

final partSearchProvider = StateProvider<String>((ref) => '');

final partLowStockFilterProvider = StateProvider<bool>((ref) => false);

final fakePartRepositoryProvider = Provider<FakePartRepository>((ref) {
  return FakePartRepository();
});
