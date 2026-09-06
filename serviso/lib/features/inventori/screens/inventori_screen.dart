import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_terms.dart';
import '../../../core/widgets/barcode_scanner_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_filter_chip.dart';
import '../../../core/widgets/neo_search_bar.dart';
import '../../../core/widgets/neo_segment_control.dart';
import '../../../core/widgets/stock_indicator_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/part_list_controller.dart';
import '../controllers/part_providers.dart';
import '../controllers/service_providers.dart';
import '../models/part.dart';
import '../models/service_item.dart';
import '../widgets/service_card.dart';
import '../widgets/service_form_dialog.dart';

enum _InventoriTab { barang, jasa }

class InventoriScreen extends ConsumerStatefulWidget {
  const InventoriScreen({super.key});

  @override
  ConsumerState<InventoriScreen> createState() => _InventoriScreenState();
}

class _InventoriScreenState extends ConsumerState<InventoriScreen> {
  _InventoriTab _selectedTab = _InventoriTab.barang;
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    if (_selectedTab == _InventoriTab.barang) {
      _searchController.text = ref.read(partSearchProvider);
    } else {
      _searchController.text = ref.read(serviceSearchProvider);
    }
  }

  void _closeSearch() {
    _searchController.clear();
    if (_selectedTab == _InventoriTab.barang) {
      ref.read(partSearchProvider.notifier).state = '';
    } else {
      ref.read(serviceSearchProvider.notifier).state = '';
    }
    setState(() => _searching = false);
  }

  void _onSearchChanged(String value) {
    if (_selectedTab == _InventoriTab.barang) {
      ref.read(partSearchProvider.notifier).state = value;
    } else {
      ref.read(serviceSearchProvider.notifier).state = value;
    }
  }

  Future<void> _confirmDeleteService(
    BuildContext context,
    ServiceItem service,
  ) async {
    final confirmed = await showNeoDialog<bool>(
      context: context,
      child: NeoDialog.alert(
        title: 'Hapus Jasa',
        content: Text(
          'Hapus "${service.name}" dari katalog jasa? Tindakan tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ThickBottomBorderButton(
            variant: ThickButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(serviceListControllerProvider.notifier)
          .deleteService(service.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final terms = ref.watch(appTermsProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final partState = ref.watch(partListControllerProvider);
    final serviceState = ref.watch(serviceListControllerProvider);
    final lowStockOnly = ref.watch(partLowStockFilterProvider);

    final showJasaTab = terms.businessType != 'barang';

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
                    hintText: _selectedTab == _InventoriTab.barang
                        ? 'Cari nama atau kode'
                        : 'Cari layanan atau kode jasa',
                    onScanTap: _selectedTab == _InventoriTab.barang
                        ? () async {
                            final code = await showBarcodeScanner(context);
                            if (code != null && code.isNotEmpty) {
                              _searchController.text = code;
                              ref.read(partSearchProvider.notifier).state =
                                  code;
                            }
                          }
                        : null,
                    onClear: _closeSearch,
                    onChanged: _onSearchChanged,
                  ),
                ),
              )
            : null,
        actions: [
          if (!_searching) ...[
            if (_selectedTab == _InventoriTab.barang)
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
              tooltip: _selectedTab == _InventoriTab.barang
                  ? 'Cari ${terms.partNoun.toLowerCase()}'
                  : 'Cari jasa',
              onPressed: _openSearch,
            ),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _selectedTab == _InventoriTab.barang
            ? ThickBottomBorderButton(
                onPressed: () => context.push(AppRoutes.inventoriTambah),
                icon: Icon(AppIcons.add, size: 18),
                child: const Text('Tambah'),
              )
            : (isAdmin
                ? ThickBottomBorderButton(
                    onPressed: () => showServiceFormDialog(context, ref),
                    icon: Icon(AppIcons.add, size: 18),
                    child: const Text('Tambah Jasa'),
                  )
                : null),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedTab == _InventoriTab.barang) {
            await ref.read(partListControllerProvider.notifier).refresh();
          } else {
            await ref.read(serviceListControllerProvider.notifier).refresh();
          }
        },
        child: Column(
          children: [
            // Top Master Tab: [Barang] vs [Jasa] (Hanya muncul jika bukan retail murni)
            if (showJasaTab)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: NeoSegmentControl<_InventoriTab>(
                  selectedValue: _selectedTab,
                  onValueChanged: (value) {
                    setState(() {
                      _selectedTab = value;
                      _closeSearch();
                    });
                  },
                  items: [
                    NeoSegmentItem<_InventoriTab>(
                      value: _InventoriTab.barang,
                      label: terms.partNoun,
                    ),
                    const NeoSegmentItem<_InventoriTab>(
                      value: _InventoriTab.jasa,
                      label: 'Jasa',
                    ),
                  ],
                ),
              ),

            // Tab Content: BARANG (Filter Chips)
            if (_selectedTab == _InventoriTab.barang) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    NeoFilterChip(
                      label: 'Semua',
                      isSelected: !lowStockOnly,
                      onTap: () {
                        ref.read(partLowStockFilterProvider.notifier).state =
                            false;
                      },
                    ),
                    const SizedBox(width: 8),
                    NeoFilterChip(
                      label: 'Stok Menipis',
                      isSelected: lowStockOnly,
                      activeColor: AppColors.pastelAmber,
                      onTap: () {
                        ref.read(partLowStockFilterProvider.notifier).state =
                            true;
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: partState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                              title:
                                  'Tidak ada ${terms.partNoun.toLowerCase()} cocok',
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
                            title: terms.emptyPartTitle,
                            message: terms.emptyPartSubtitle,
                            actionLabel: terms.addPartLabel,
                            onAction: () =>
                                context.push(AppRoutes.inventoriTambah),
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
                                          .read(
                                              partListControllerProvider.notifier)
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

            // Tab Content: JASA (Hanya katalog tarif, tanpa stok)
            if (_selectedTab == _InventoriTab.jasa) ...[
              const SizedBox(height: 8),
              Expanded(
                child: serviceState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref
                        .read(serviceListControllerProvider.notifier)
                        .refresh(),
                  ),
                  data: (services) {
                    if (services.isEmpty) {
                      final searching =
                          ref.read(serviceSearchProvider).trim().isNotEmpty;
                      if (searching) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            EmptyState(
                              icon: AppIcons.search,
                              title: 'Tidak ada jasa cocok',
                              message:
                                  'Coba kata kunci lain untuk mencari layanan jasa.',
                            ),
                          ],
                        );
                      }
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          EmptyState(
                            icon: AppIcons.wrench,
                            title: 'Belum ada jasa di katalog',
                            message: isAdmin
                                ? 'Tambahkan layanan jasa dan tarif tetap untuk mempercepat pembuatan transaksi.'
                                : 'Hubungi pemilik toko untuk menambahkan layanan jasa.',
                            actionLabel: isAdmin ? 'Tambah Jasa' : null,
                            onAction: isAdmin
                                ? () => showServiceFormDialog(context, ref)
                                : null,
                          ),
                        ],
                      );
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      children: [
                        for (final s in services) ...[
                          ServiceCard(
                            service: s,
                            isAdmin: isAdmin,
                            onTap: isAdmin
                                ? () => showServiceFormDialog(
                                      context,
                                      ref,
                                      initialService: s,
                                    )
                                : null,
                            onDelete: isAdmin
                                ? () => _confirmDeleteService(context, s)
                                : null,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
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
