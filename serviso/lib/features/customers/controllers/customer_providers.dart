import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/session_controller.dart';
import '../data/customer_repository.dart';
import '../data/fakes.dart';
import '../data/vehicle_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository(ref.watch(supabaseClientProvider));
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return SupabaseVehicleRepository(ref.watch(supabaseClientProvider));
});

final customerSearchProvider = StateProvider<String>((ref) => '');

final vehicleSearchProvider = StateProvider<String>((ref) => '');

class FakeCustomerRepositories {
  FakeCustomerRepositories({
    FakeCustomerRepository? customers,
    FakeVehicleRepository? vehicles,
  })  : customers = customers ?? FakeCustomerRepository(),
        vehicles = vehicles ?? FakeVehicleRepository();

  final FakeCustomerRepository customers;
  final FakeVehicleRepository vehicles;
}

final fakeCustomerRepositoriesProvider = Provider<FakeCustomerRepositories>((ref) {
  return FakeCustomerRepositories();
});
