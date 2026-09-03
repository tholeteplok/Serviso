import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/neo_bottom_sheet.dart';
import '../../../../core/widgets/neo_card.dart';
import '../../controllers/report_controllers.dart';
import '../../models/report_models.dart';

class DebtHistorySheet extends ConsumerWidget {
  final DistributorDebtItem debt;

  const DebtHistorySheet({
    super.key,
    required this.debt,
  });

  static Future<void> show(BuildContext context, DistributorDebtItem debt) {
    return showNeoBottomSheet(
      context: context,
      title: 'Riwayat Pembayaran Hutang',
      child: DebtHistorySheet(debt: debt),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(debtPaymentsProvider(debt.movementId));
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pembayaran',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeoCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.distributor,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  debt.partName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Hutang', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.inkMuted)),
                    Text(
                      rupiah(debt.totalDebt),
                      style: AppTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Catatan Pembayaran',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          historyAsync.when(
            data: (payments) {
              if (payments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Belum ada riwayat cicilan.'),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: payments.length,
                  separatorBuilder: (context, index) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.pastelMint.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              size: 16,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateShortId(p.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (p.payMethod != null && p.payMethod!.isNotEmpty)
                                  Text(
                                    'Metode: ${p.payMethod}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.inkMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                if (p.note != null && p.note!.isNotEmpty)
                                  Text(
                                    p.note!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            rupiah(p.amount),
                            style: AppTypography.mono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Terbayar', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.inkMuted)),
              Text(
                rupiah(debt.totalPaid),
                style: AppTypography.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sisa Hutang', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                rupiah(debt.remaining),
                style: AppTypography.mono(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: debt.remaining > 0 ? AppColors.action : AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

