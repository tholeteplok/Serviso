import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customer_repository.dart';
import '../models/customer.dart';
import 'customer_providers.dart';

class CustomerListData {
  const CustomerListData({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Customer> items;
  final bool hasMore;
  final bool loadingMore;

  CustomerListData copyWith({
    List<Customer>? items,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      CustomerListData(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class CustomerListController
    extends AsyncNotifier<CustomerListData> {
  static const _pageSize = 50;

  late CustomerRepository _repo;
  String _query = '';
  int _offset = 0;
  bool _hasMore = true;
  final List<Customer> _items = [];

  @override
  Future<CustomerListData> build() async {
    _repo = ref.watch(customerRepositoryProvider);
    _query = ref.read(customerSearchProvider);
    ref.listen(customerSearchProvider, (_, next) => _runSearch(next));

    _items.clear();
    _offset = 0;
    _hasMore = true;
    await _fetch(notify: false);
    return CustomerListData(items: List.of(_items), hasMore: _hasMore);
  }

  Future<void> _fetch({bool notify = true}) async {
    final fetched = _query.isEmpty
        ? await _repo.list(limit: _pageSize, offset: _offset)
        : await _repo.search(
            _query,
            limit: _pageSize,
            offset: _offset,
          );
    if (fetched.length < _pageSize) _hasMore = false;
    _items.addAll(fetched);
    if (notify) {
      state = AsyncData(
        CustomerListData(items: List.of(_items), hasMore: _hasMore),
      );
    }
  }

  Future<void> _runSearch(String query) async {
    _query = query;
    _items.clear();
    _offset = 0;
    _hasMore = true;
    state = const AsyncLoading();
    try {
      await _fetch(notify: false);
      state = AsyncData(
        CustomerListData(items: List.of(_items), hasMore: _hasMore),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    _offset = _items.length;
    try {
      await _fetch(notify: false);
      state = AsyncData(
        CustomerListData(items: List.of(_items), hasMore: _hasMore),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    _items.clear();
    _offset = 0;
    _hasMore = true;
    state = const AsyncLoading();
    try {
      await _fetch(notify: false);
      state = AsyncData(
        CustomerListData(items: List.of(_items), hasMore: _hasMore),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final customerListControllerProvider =
    AsyncNotifierProvider<CustomerListController, CustomerListData>(
  CustomerListController.new,
);
