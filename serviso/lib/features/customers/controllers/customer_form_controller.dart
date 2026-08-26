import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import 'customer_providers.dart';

class CustomerFormController
    extends AutoDisposeFamilyAsyncNotifier<void, Customer?> {
  @override
  Future<void> build(Customer? arg) async {}

  Future<void> submit({
    required String name,
    required String phone,
    required String address,
    required String note,
  }) async {
    final repo = ref.read(customerRepositoryProvider);
    final input = CustomerInput(
      id: arg?.id,
      name: name,
      phone: phone,
      address: address,
      note: note,
    );
    state = const AsyncLoading();
    try {
      if (arg == null) {
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

final customerFormControllerProvider =
    AsyncNotifierProvider.autoDispose.family<CustomerFormController, void,
        Customer?>(
  CustomerFormController.new,
);
