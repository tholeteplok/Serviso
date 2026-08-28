import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/plate_chip.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/controllers/session_controller.dart';
import '../controllers/customer_detail_controller.dart';
import '../screens/customer_form_sheet.dart';
import '../screens/vehicle_form_sheet.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = AppTypography.textTheme();
    final state = ref.watch(customerDetailControllerProvider(customerId));
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus pelanggan',
              onPressed: () => _confirmDeleteCustomer(context, ref),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showVehicleForm(
          context: context,
          ref: ref,
          customerId: customerId,
          onSaved: () =>
              ref.read(customerDetailControllerProvider(customerId).notifier).reload(),
        ),
        icon: const Icon(Icons.directions_car_outlined),
        label: const Text('Kendaraan Baru'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(customerDetailControllerProvider(customerId).notifier).reload(),
        ),
        data: (data) {
          final customer = data.customer;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Ubah'),
                    onPressed: () => showCustomerForm(
                      context,
                      ref,
                      customer,
                      onSaved: () => ref
                          .read(customerDetailControllerProvider(customerId)
                              .notifier)
                          .reload(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Kontak',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Telepon',
                      value: customer.phone?.isNotEmpty == true
                          ? customer.phone!
                          : 'Belum diisi',
                    ),
                    _InfoRow(
                      icon: Icons.home_outlined,
                      label: 'Alamat',
                      value: customer.address?.isNotEmpty == true
                          ? customer.address!
                          : 'Belum diisi',
                    ),
                    _InfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Work order',
                      value: '${data.workOrderCount}',
                      mono: true,
                    ),
                    if (customer.note?.isNotEmpty == true)
                      _InfoRow(
                        icon: Icons.notes_outlined,
                        label: 'Catatan',
                        value: customer.note!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Kendaraan',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.vehicles.length}',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah'),
                      onPressed: () => showVehicleForm(
                        context: context,
                        ref: ref,
                        customerId: customerId,
                        onSaved: () => ref
                            .read(customerDetailControllerProvider(customerId)
                                .notifier)
                            .reload(),
                      ),
                    ),
                  ],
                ),
                child: data.vehicles.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: EmptyState(
                          icon: Icons.directions_car_outlined,
                          title: 'Belum ada kendaraan',
                          message:
                              'Tambahkan kendaraan milik pelanggan ini.',
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.vehicles.length,
                        separatorBuilder: (_, _) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final vehicle = data.vehicles[index];
                          final subtitle = [
                            if (vehicle.brand != null) vehicle.brand!,
                            if (vehicle.model != null) vehicle.model!,
                            if (vehicle.year != null) vehicle.year.toString(),
                          ].join(' ');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: PlateChip(plateText: vehicle.plateNo),
                            title: Text(
                              subtitle.isNotEmpty ? subtitle : 'Kendaraan',
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: InkWell(
                                onTap: () => context.push(
                                  AppRoutes.woBaru,
                                  extra: vehicle,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_task_rounded,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Buat Work Order',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            trailing: isAdmin
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Ubah kendaraan',
                                        onPressed: () => showVehicleForm(
                                          context: context,
                                          ref: ref,
                                          customerId: customerId,
                                          initial: vehicle,
                                          onSaved: () => ref
                                              .read(customerDetailControllerProvider(
                                                      customerId)
                                                  .notifier)
                                              .reload(),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.action,
                                        ),
                                        tooltip: 'Hapus kendaraan',
                                        onPressed: () =>
                                            _confirmDeleteVehicle(
                                          context,
                                          ref,
                                          vehicle,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteCustomer(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus pelanggan'),
        content: const Text(
          'Hapus pelanggan ini beserta seluruh datanya? Tindakan tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.action,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(customerDetailControllerProvider(customerId).notifier)
          .deleteCustomer();
      if (!context.mounted) return;
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _confirmDeleteVehicle(
    BuildContext context,
    WidgetRef ref,
    vehicle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus kendaraan'),
        content: Text(
          'Hapus kendaraan ${vehicle.plateNo}? Tindakan tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.action,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(customerDetailControllerProvider(customerId).notifier)
          .deleteVehicle(vehicle.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: mono
                      ? AppTypography.mono(fontSize: 14)
                      : textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
