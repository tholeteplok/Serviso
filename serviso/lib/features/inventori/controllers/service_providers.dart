import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/session_controller.dart';
import '../data/service_repository.dart';
import '../models/service_item.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return SupabaseServiceRepository(ref.watch(supabaseClientProvider));
});

final serviceSearchProvider = StateProvider<String>((ref) => '');

class ServiceListController extends AsyncNotifier<List<ServiceItem>> {
  late ServiceRepository _repo;
  Timer? _searchDebounce;

  @override
  Future<List<ServiceItem>> build() async {
    _repo = ref.watch(serviceRepositoryProvider);
    final query = ref.watch(serviceSearchProvider);

    ref.onDispose(() => _searchDebounce?.cancel());

    return _repo.list(search: query);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final query = ref.read(serviceSearchProvider);
      return _repo.list(search: query);
    });
  }

  Future<ServiceItem> createService(ServiceInput input) async {
    final item = await _repo.create(input);
    await refresh();
    return item;
  }

  Future<ServiceItem> updateService(String id, ServiceInput input) async {
    final item = await _repo.update(id, input);
    await refresh();
    return item;
  }

  Future<void> deleteService(String id) async {
    await _repo.delete(id);
    await refresh();
  }
}

final serviceListControllerProvider =
    AsyncNotifierProvider<ServiceListController, List<ServiceItem>>(
  ServiceListController.new,
);
