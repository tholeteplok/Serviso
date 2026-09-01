import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_search_bar.dart';
import '../controllers/customer_list_controller.dart';
import '../controllers/customer_providers.dart';
import '../screens/customer_form_sheet.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _searchController.text = ref.read(customerSearchProvider);
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(customerSearchProvider.notifier).state = '';
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final state = ref.watch(customerListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching ? null : const Text('Pelanggan'),
        bottom: _searching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: NeoSearchBar(
                    controller: _searchController,
                    hintText: 'Cari nama atau telepon',
                    autofocus: true,
                    onChanged: (value) =>
                        ref.read(customerSearchProvider.notifier).state = value,
                    onClear: _closeSearch,
                  ),
                ),
              )
            : null,
        actions: [
          if (!_searching)
            IconButton(
              icon: Icon(AppIcons.search),
              tooltip: 'Cari pelanggan',
              onPressed: _openSearch,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCustomerForm(context, ref, null),
        icon: Icon(AppIcons.addPerson),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerListControllerProvider.notifier).refresh(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () =>
                ref.read(customerListControllerProvider.notifier).refresh(),
          ),
          data: (data) {
            if (data.items.isEmpty) {
              final searchingEmpty =
                  ref.read(customerSearchProvider).trim().isNotEmpty;
              if (searchingEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: const [
                    EmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'Tidak ada pelanggan cocok',
                      message: 'Coba kata kunci lain untuk nama atau nomor telepon.',
                    ),
                  ],
                );
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  EmptyState(
                    icon: Icons.people_outline,
                    title: 'Belum ada pelanggan',
                    message:
                        'Tambahkan pelanggan untuk mencatat kendaraan dan layanan bengkel.',
                    actionLabel: 'Tambah Pelanggan',
                    onAction: () => showCustomerForm(context, ref, null),
                  ),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                for (final customer in data.items) ...[
                  NeoCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.push('/pelanggan/${customer.id}'),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.pastelMint,
                            border: Border.all(
                              color: AppColors.borderInk,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.ink900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (customer.phone != null &&
                                  customer.phone!.isNotEmpty)
                                Text(
                                  customer.phone!,
                                  style: textTheme.bodySmall,
                                ),
                              Text(
                                '${customer.vehicleCount} kendaraan',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ],
                if (data.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: data.loadingMore
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: () => ref
                                  .read(customerListControllerProvider.notifier)
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
    );
  }
}
