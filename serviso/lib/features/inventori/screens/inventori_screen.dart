import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_search_bar.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/stock_indicator_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../../core/router/app_router.dart';
import '../controllers/part_list_controller.dart';
import '../controllers/part_providers.dart';
import '../models/part.dart';

enum _FilterOption { all, lowStock }

class InventoriScreen extends ConsumerStatefulWidget {
  const InventoriScreen({super.key});

  @override
  ConsumerState<InventoriScreen> createState() => _InventoriScreenState();
}

class _InventoriScreenState extends ConsumerState<InventoriScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _searchController.text = ref.read(partSearchProvider);
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(partSearchProvider.notifier).state = '';
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partListControllerProvider);
    final lowStockOnly = ref.watch(partLowStockFilterProvider);

    return Scaffold(
      appBar: NeoAppBar(
        title: _searching ? null : 'Inventori',
        showBack: false,
        bottom: _searching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: NeoSearchBar(
                    controller: _searchController,
                    hintText: 'Cari nama atau kode',
                    onScanTap: () async {
                      final code = await showBarcodeScanner(context);
                      if (code != null && code.isNotEmpty) {
                        _searchController.text = code;
                        ref.read(partSearchProvider.notifier).state = code;
                      }
                    },
                    onClear: _closeSearch,
                    onChanged: (value) =>
                        ref.read(partSearchProvider.notifier).state = value,
                  ),
                ),
              )
            : null,
        actions: [
          if (!_searching) ...[
            IconButton(
              icon: Icon(
                AppIcons.barcode,
                size: 22,
                color: AppColors.ink900,
              ),
              tooltip: 'Scan Barcode',
              onPressed: () async {
                final code = await showBarcodeScanner(context);
                if (code != null && code.isNotEmpty) {
                  _openSearch();
                  _searchController.text = code;
                  ref.read(partSearchProvider.notifier).state = code;
                }
              },
            ),
            IconButton(
              icon: Icon(AppIcons.search, color: AppColors.ink900),
              tooltip: 'Cari suku cadang',
              onPressed: _openSearch,
            ),
          ],
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ThickBottomBorderButton(
          onPressed: () => context.push(AppRoutes.inventoriTambah),
          icon: Icon(AppIcons.add, size: 18),
          child: const Text('Tambah'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(partListControllerProvider.notifier).refresh(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: NeoSegmentControl<_FilterOption>(
                selectedValue: lowStockOnly ? _FilterOption.lowStock : _FilterOption.all,
                onValueChanged: (value) {
                  ref.read(partLowStockFilterProvider.notifier).state = value == _FilterOption.lowStock;
                },
                activeColor: AppColors.pastelMint,
                items: const [
                  NeoSegmentItem<_FilterOption>(
                    value: _FilterOption.all,
                    label: 'Semua',
                  ),
                  NeoSegmentItem<_FilterOption>(
                    value: _FilterOption.lowStock,
                    label: 'Stok Menipis',
                    activeColor: AppColors.pastelYellow,
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.read(partListControllerProvider.notifier).refresh(),
                ),
                data: (data) {
                  if (data.items.isEmpty) {
                    final searching =
                        ref.read(partSearchProvider).trim().isNotEmpty;
                    final lowStock = ref.read(partLowStockFilterProvider);
                    if (searching || lowStock) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          EmptyState(
                            icon: AppIcons.search,
                            title: 'Tidak ada suku cadang cocok',
                            message:
                                'Coba kata kunci lain atau ubah filter stok menipis.',
                          ),
                        ],
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        EmptyState(
                          icon: AppIcons.inventory,
                          title: 'Belum ada suku cadang',
                          message:
                              'Tambahkan suku cadang untuk mencatat stok bengkel.',
                          actionLabel: 'Tambah Suku Cadang',
                          onAction: () => context.push(AppRoutes.inventoriTambah),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    children: [
                      for (final part in data.items) ...[
                        _PartCard(part: part),
                        const SizedBox(height: 8),
                      ],
                      if (data.hasMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: data.loadingMore
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: () => ref
                                        .read(partListControllerProvider.notifier)
                                        .loadMore(),
                                    child: const Text('Muat lagi'),
                                  ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({required this.part});

  final Part part;

  @override
  Widget build(BuildContext context) {
    return StockIndicatorCard(
      name: part.name,
      code: part.code,
      stockQty: part.stockQty,
      minStock: part.minStock,
      unit: part.unit ?? 'pcs',
      sellPrice: part.sellPrice,
      costPrice: part.costPrice,
      onTap: () => context.push('/inventori/${part.id}'),
    );
  }
}
