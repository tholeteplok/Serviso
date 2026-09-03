import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_expandable_card.dart';
import '../controllers/admin_controllers.dart';
import '../widgets/json_diff_viewer.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final Set<int> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final filter = ref.watch(auditLogFilterProvider);
    final auditLogsAsync = ref.watch(auditLogListProvider);

    return Scaffold(
      appBar: const NeoAppBar(
        title: 'Audit Log Sistem',
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: filter.tableName,
                    decoration: const InputDecoration(
                      labelText: 'Tabel',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Tabel')),
                      DropdownMenuItem(value: 'work_orders', child: Text('work_orders')),
                      DropdownMenuItem(value: 'parts', child: Text('parts')),
                      DropdownMenuItem(value: 'part_movements', child: Text('part_movements')),
                      DropdownMenuItem(value: 'customers', child: Text('customers')),
                      DropdownMenuItem(value: 'vehicles', child: Text('vehicles')),
                      DropdownMenuItem(value: 'auth', child: Text('auth')),
                    ],
                    onChanged: (val) {
                      ref.read(auditLogFilterProvider.notifier).state =
                          filter.copyWith(tableName: val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: filter.action,
                    decoration: const InputDecoration(
                      labelText: 'Aksi',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Aksi')),
                      DropdownMenuItem(value: 'insert', child: Text('INSERT')),
                      DropdownMenuItem(value: 'update', child: Text('UPDATE')),
                      DropdownMenuItem(value: 'delete', child: Text('DELETE')),
                      DropdownMenuItem(value: 'login', child: Text('LOGIN')),
                      DropdownMenuItem(value: 'logout', child: Text('LOGOUT')),
                    ],
                    onChanged: (val) {
                      ref.read(auditLogFilterProvider.notifier).state =
                          filter.copyWith(action: val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),

          // Audit Logs List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(auditLogListProvider),
              child: auditLogsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(auditLogListProvider),
                ),
                data: (logs) {
                  if (logs.isEmpty) {
                    return EmptyState(
                      icon: AppIcons.clipboardList,
                      title: 'Belum Ada Log Audit',
                      message:
                          'Aktivitas CRUD dan autentikasi akan tercatat otomatis di sini.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isExpanded = _expandedIds.contains(log.id);

                      return NeoExpandableCard(
                        isExpanded: isExpanded,
                        onExpansionChanged: (val) {
                          setState(() {
                            if (val) {
                              _expandedIds.add(log.id);
                            } else {
                              _expandedIds.remove(log.id);
                            }
                          });
                        },
                        header: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildActionChip(log.action),
                                const SizedBox(width: 8),
                                Text(
                                  log.tableName,
                                  style: AppTypography.mono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Oleh ${log.actorName}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.ink900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  dateTimeId(log.createdAt),
                                  style: AppTypography.mono(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (log.recordId.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'ID Record: ${log.recordId}',
                                style: AppTypography.mono(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        expandedChild: JsonDiffViewer(
                          oldData: log.oldData,
                          newData: log.newData,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String action) {
    Color bg;
    Color fg = AppColors.ink900;

    switch (action.toLowerCase()) {
      case 'insert':
        bg = AppColors.pastelMint;
        break;
      case 'update':
        bg = AppColors.pastelBlue;
        break;
      case 'delete':
        bg = AppColors.pastelPink;
        fg = AppColors.statusDanger;
        break;
      case 'login':
      case 'logout':
      default:
        bg = AppColors.pastelYellow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.badge,
        border: Border.all(color: AppColors.borderInk, width: 1),
      ),
      child: Text(
        action.toUpperCase(),
        style: AppTypography.mono(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
