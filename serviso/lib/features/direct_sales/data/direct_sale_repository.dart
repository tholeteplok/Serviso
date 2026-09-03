import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/direct_sale.dart';
import '../../workorders/data/repository_exception.dart';
import '../../workorders/models/payment.dart';

abstract class DirectSaleRepository {
  Future<DirectSaleResult> checkout(DirectSaleDraft draft);
}

class SupabaseDirectSaleRepository implements DirectSaleRepository {
  SupabaseDirectSaleRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<DirectSaleResult> checkout(DirectSaleDraft draft) async {
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

      if (res is Map<String, dynamic>) {
        return DirectSaleResult.fromMap(res);
      } else if (res is Map) {
        return DirectSaleResult.fromMap(Map<String, dynamic>.from(res));
      } else if (res is String) {
        if (res.startsWith('DS-') || res.startsWith('PL-') || res.startsWith('WO-')) {
          return DirectSaleResult(id: res, saleNumber: res);
        }
        try {
          final row = await _client
              .from('direct_sales')
              .select('id, sale_number')
              .eq('id', res)
              .maybeSingle();
          if (row != null) {
            return DirectSaleResult.fromMap(row);
          }
        } catch (_) {}
        return DirectSaleResult(id: res, saleNumber: res);
      }
      return const DirectSaleResult(id: '', saleNumber: '');
    } catch (e) {
      throw RepositoryException(mapRepositoryError(e));
    }
  }
}

class FakeDirectSaleRepository implements DirectSaleRepository {
  DirectSaleResult? lastCheckoutResult;
  DirectSaleDraft? lastDraft;
  int _counter = 1;

  @override
  Future<DirectSaleResult> checkout(DirectSaleDraft draft) async {
    if (draft.items.isEmpty) {
      throw const RepositoryException('Minimal 1 item diperlukan');
    }
    lastDraft = draft;
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final seq = (_counter++).toString().padLeft(3, '0');
    final saleNumber = 'DS-$yy$mm$dd-$seq';
    final id = 'ds_${now.millisecondsSinceEpoch}';
    lastCheckoutResult = DirectSaleResult(id: id, saleNumber: saleNumber);
    return lastCheckoutResult!;
  }
}
