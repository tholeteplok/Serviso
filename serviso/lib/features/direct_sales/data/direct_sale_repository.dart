import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/direct_sale.dart';
import '../../workorders/data/repository_exception.dart';
import '../../workorders/models/payment.dart';

abstract class DirectSaleRepository {
  Future<String> checkout(DirectSaleDraft draft);
}

class SupabaseDirectSaleRepository implements DirectSaleRepository {
  SupabaseDirectSaleRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<String> checkout(DirectSaleDraft draft) async {
    if (draft.items.isEmpty) {
      throw const RepositoryException('Minimal 1 item diperlukan');
    }
    try {
      final res = await _client.rpc('checkout_direct_sale', params: {
        'p_customer_id': draft.customerId,
        'p_items': draft.items.map((e) => e.toJson()).toList(),
        'p_pay_method': draft.payMethod.value,
        'p_paid_amount': draft.paidAmount,
      });
      return res as String;
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }
}

class FakeDirectSaleRepository implements DirectSaleRepository {
  String? lastCheckoutId;
  DirectSaleDraft? lastDraft;
  @override
  Future<String> checkout(DirectSaleDraft draft) async {
    if (draft.items.isEmpty) throw const RepositoryException('Minimal 1 item diperlukan');
    lastDraft = draft;
    lastCheckoutId = 'PL-${DateTime.now().millisecondsSinceEpoch}';
    return lastCheckoutId!;
  }
}
