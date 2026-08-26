import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../models/vehicle.dart';
import '../data/repository_exception.dart';
import 'customer_list_controller.dart';
import 'customer_providers.dart';

class CustomerDetailData {
  const CustomerDetailData({
    required this.customer,
    required this.vehicles,
    required this.workOrderCount,
  });

  final Customer customer;
  final List<Vehicle> vehicles;
  final int workOrderCount;
}

class CustomerDetailController
    extends AutoDisposeFamilyAsyncNotifier<CustomerDetailData, String> {
  @override
  Future<CustomerDetailData> build(String arg) async {
    final customerRepo = ref.watch(customerRepositoryProvider);
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);

    final customer = await customerRepo.getById(arg);
    if (customer == null) {
      throw const RepositoryException('Pelanggan tidak ditemukan');
    }
    final vehicles = await vehicleRepo.listByCustomer(arg);
    final workOrderCount = await customerRepo.workOrderCount(arg);
    return CustomerDetailData(
      customer: customer,
      vehicles: vehicles,
      workOrderCount: workOrderCount,
    );
  }

  Future<void> deleteCustomer() async {
    final customerRepo = ref.read(customerRepositoryProvider);
    await customerRepo.delete(arg);
    ref.invalidate(customerListControllerProvider);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final vehicleRepo = ref.read(vehicleRepositoryProvider);
    await vehicleRepo.delete(vehicleId);
    ref.invalidateSelf();
  }

  Future<void> reload() async => ref.invalidateSelf();
}

final customerDetailControllerProvider =
    AsyncNotifierProvider.autoDispose.family<CustomerDetailController,
        CustomerDetailData, String>(
  CustomerDetailController.new,
);
