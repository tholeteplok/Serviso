import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/part_repository.dart';
import '../models/part.dart';
import 'part_providers.dart';

class PartListData {
  const PartListData({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Part> items;
  final bool hasMore;
  final bool loadingMore;

  PartListData copyWith({
    List<Part>? items,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      PartListData(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class PartListController extends AsyncNotifier<PartListData> {
  static const _pageSize = 50;

  late PartRepository _repo;
  String _query = '';
  bool _lowStockOnly = false;
  int _offset = 0;
  bool _hasMore = true;
  final List<Part> _items = [];

  Timer? _searchDebounce;

  @override
  Future<PartListData> build() async {
    _repo = ref.watch(partRepositoryProvider);
    _query = ref.read(partSearchProvider);
    _lowStockOnly = ref.read(partLowStockFilterProvider);
    ref.onDispose(() => _searchDebounce?.cancel());
    ref.listen(partSearchProvider, (_, next) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () => _runSearch(next));
    });
    ref.listen(partLowStockFilterProvider, (_, next) => _runFilter(next));

    _items.clear();
    _offset = 0;
    _hasMore = true;
    await _fetch(notify: false);
    return PartListData(items: List.of(_items), hasMore: _hasMore);
  }

  Future<void> _fetch({bool notify = true}) async {
    final fetched = await _repo.list(
      search: _query.isEmpty ? null : _query,
      filterLowStock: _lowStockOnly,
      limit: _pageSize,
      offset: _offset,
    );
    if (fetched.length < _pageSize) _hasMore = false;
    _items.addAll(fetched);
    if (notify) {
      state = AsyncData(
        PartListData(items: List.of(_items), hasMore: _hasMore),
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
      state = AsyncData(PartListData(items: List.of(_items), hasMore: _hasMore));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _runFilter(bool lowStockOnly) async {
    _lowStockOnly = lowStockOnly;
    _items.clear();
    _offset = 0;
    _hasMore = true;
    state = const AsyncLoading();
    try {
      await _fetch(notify: false);
      state = AsyncData(PartListData(items: List.of(_items), hasMore: _hasMore));
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
      state = AsyncData(PartListData(items: List.of(_items), hasMore: _hasMore));
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
      state = AsyncData(PartListData(items: List.of(_items), hasMore: _hasMore));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final partListControllerProvider =
    AsyncNotifierProvider<PartListController, PartListData>(
  PartListController.new,
);
