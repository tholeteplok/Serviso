import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
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
      appBar: AppBar(
        title: const Text('Audit Log Sistem'),
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
                    return const EmptyState(
                      icon: Icons.history_edu_outlined,
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

                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedIds.remove(log.id);
                              } else {
                                _expandedIds.add(log.id);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
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
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: AppColors.inkMuted,
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
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      dateTimeId(log.createdAt),
                                      style: AppTypography.mono(
                                        fontSize: 11,
                                        color: AppColors.inkMuted,
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
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                                if (isExpanded) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: AppColors.line),
                                  const SizedBox(height: 12),
                                  JsonDiffViewer(
                                    oldData: log.oldData,
                                    newData: log.newData,
                                  ),
                                ],
                              ],
                            ),
                          ),
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
    Color fg;

    switch (action.toLowerCase()) {
      case 'insert':
        bg = AppColors.teal.withValues(alpha: 0.12);
        fg = AppColors.teal;
        break;
      case 'update':
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        break;
      case 'delete':
        bg = AppColors.action.withValues(alpha: 0.12);
        fg = AppColors.action;
        break;
      case 'login':
      case 'logout':
      default:
        bg = AppColors.inkMuted.withValues(alpha: 0.12);
        fg = AppColors.inkMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
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
