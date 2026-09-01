import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/laporan/models/report_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'neo_card.dart';
import 'plate_chip.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.row,
    this.onTapOverride,
  });

  final TransactionRow row;
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context) {
    final isWo = row.isWo;
    void defaultTap() {
      if (onTapOverride != null) {
        onTapOverride!.call();
        return;
      }
      if (isWo) {
        context.push('/antrian/${row.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${row.number} • ${rupiah(row.amount)} • ${row.itemCount} item')),
        );
      }
    }

    return NeoCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: defaultTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (isWo && row.plateNo != null && row.plateNo!.isNotEmpty)
                    PlateChip(plateText: row.plateNo!)
                  else if (isWo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.inkMuted, width: 1.2)),
                      child: Text('-', style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w700)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.pastelBlue.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderStrong, width: 1.2)),
                      child: Text('PL', style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink900)),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(row.number,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: isWo ? AppColors.pastelPurple.withValues(alpha: 0.35) : AppColors.pastelBlue.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderStrong, width: 1)),
                    child: Text(isWo ? 'Servis' : 'Langsung',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 9)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(row.customerName ?? (isWo ? '-' : 'Pelanggan umum'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${dateShortId(row.transactedAt)} • ${row.itemCount} item • ${_payLabel(row.payMethod)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(rupiah(row.amount),
                style: AppTypography.mono(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: _payBg(row.payMethod), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.borderStrong, width: 1)),
              child: Text(_payLabel(row.payMethod),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMuted),
          ]),
        ],
      ),
    );
  }

  String _payLabel(String? v) {
    switch (v) {
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      case 'cash':
        return 'Tunai';
      default:
        return 'Tunai';
    }
  }

  Color _payBg(String? v) {
    switch (v) {
      case 'transfer':
        return AppColors.pastelBlue;
      case 'qris':
        return AppColors.pastelYellow;
      default:
        return AppColors.pastelMint;
    }
  }
}
