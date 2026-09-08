import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/direct_sale.dart';
import '../../workorders/models/payment.dart';
import '../../workorders/models/work_order.dart';

class HoldSaleDraft {
  final String id;
  final String? note;
  final String? customerId;
  final String? customerName;
  final DateTime createdAt;
  final List<DirectSaleItemInput> items;
  final PaymentMethod payMethod;
  final double paidAmount;

  const HoldSaleDraft({
    required this.id,
    this.note,
    this.customerId,
    this.customerName,
    required this.createdAt,
    required this.items,
    this.payMethod = PaymentMethod.cash,
    this.paidAmount = 0.0,
  });

  double get total => items.fold(0.0, (sum, i) => sum + i.lineTotal);

  Map<String, dynamic> toMap() => {
        'id': id,
        'note': note,
        'customer_id': customerId,
        'customer_name': customerName,
        'created_at': createdAt.toIso8601String(),
        'pay_method': payMethod.value,
        'paid_amount': paidAmount,
        'items': items
            .map((i) => {
                  'kind': i.kind == WoItemKind.part ? 'part' : 'jasa',
                  'part_id': i.partId,
                  'description': i.description,
                  'qty': i.qty,
                  'unit_price': i.unitPrice,
                  'discount': i.discount,
                })
            .toList(),
      };

  factory HoldSaleDraft.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? [];
    final items = rawItems.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return DirectSaleItemInput(
        kind: m['kind'] == 'part' ? WoItemKind.part : WoItemKind.jasa,
        partId: m['part_id'] as String?,
        description: m['description'] as String?,
        qty: (m['qty'] as num?)?.toDouble() ?? 1.0,
        unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0.0,
        discount: (m['discount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return HoldSaleDraft(
      id: map['id'] as String? ?? '',
      note: map['note'] as String?,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      items: items,
      payMethod: PaymentMethodX.fromValue(map['pay_method'] as String?),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HoldTransactionNotifier extends StateNotifier<List<HoldSaleDraft>> {
  HoldTransactionNotifier() : super([]) {
    _init();
  }

  static const _storageKey = 'serviso_hold_sale_drafts';
  bool _initialized = false;

  Future<void> _init() async {
    await loadDrafts();
    _initialized = true;
  }

  Future<void> loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        state = decoded
            .map((e) => HoldSaleDraft.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        if (!_initialized && state.isNotEmpty) return;
        state = [];
      }
    } catch (_) {
      if (!_initialized && state.isNotEmpty) return;
      state = [];
    }
  }

  Future<void> saveDraft(HoldSaleDraft draft) async {
    final updated = [
      draft,
      ...state.where((d) => d.id != draft.id),
    ];
    state = updated;
    await _persist();
  }

  Future<void> deleteDraft(String id) async {
    state = state.where((d) => d.id != id).toList();
    await _persist();
  }

  Future<void> clearAll() async {
    state = [];
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}

final holdDraftsProvider =
    StateNotifierProvider<HoldTransactionNotifier, List<HoldSaleDraft>>((ref) {
  return HoldTransactionNotifier();
});
