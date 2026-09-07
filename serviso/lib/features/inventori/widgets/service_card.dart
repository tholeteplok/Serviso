import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../models/service_item.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.isAdmin = false,
    this.onTap,
    this.onDelete,
  });

  final ServiceItem service;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderStrong, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.card,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Service Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.pastelAmber,
                    borderRadius: AppRadius.button,
                    border: Border.all(
                      color: AppColors.borderStrong,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    AppIcons.wrench,
                    size: 20,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(width: 12),

                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        service.name,
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (service.code != null && service.code!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pastelCream,
                                borderRadius: AppRadius.badge,
                                border: Border.all(
                                  color: AppColors.borderStrong,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                service.code!,
                                style: AppTypography.mono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pastelMint,
                              borderRadius: AppRadius.badge,
                              border: Border.all(
                                color: AppColors.borderStrong,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'Tarif Tetap',
                              style: AppTypography.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Tariff Price & Admin Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rupiah(service.price),
                      style: AppTypography.chakra(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onTap,
                            borderRadius: AppRadius.sm,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                AppIcons.edit,
                                size: 16,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: onDelete,
                              borderRadius: AppRadius.sm,
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  AppIcons.trash,
                                  size: 16,
                                  color: AppColors.statusDanger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
