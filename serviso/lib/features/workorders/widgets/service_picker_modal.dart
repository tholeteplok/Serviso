import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../inventori/controllers/service_providers.dart';
import '../../inventori/models/service_item.dart';

Future<ServiceItem?> showServicePicker(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<ServiceItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ServicePickerSheet(ref: ref),
  );
}

class _ServicePickerSheet extends StatefulWidget {
  const _ServicePickerSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  final _searchController = TextEditingController();
  List<ServiceItem>? _services;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchServices('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices(String query) async {
    setState(() => _loading = true);
    try {
      final repo = widget.ref.read(serviceRepositoryProvider);
      final list = await repo.list(search: query, limit: 30);
      if (mounted) {
        setState(() {
          _services = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _services = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderInk.withAlpha(80),
                  borderRadius: AppRadius.sm,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Jasa',
                  style: AppTypography.chakra(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(AppIcons.close, color: AppColors.ink900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode jasa...',
                prefixIcon: Icon(AppIcons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(AppIcons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchServices('');
                        },
                      )
                    : null,
              ),
              onChanged: (q) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 300),
                  () => _fetchServices(q),
                );
              },
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_services == null || _services!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.wrench, size: 40, color: AppColors.inkMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada jasa ditemukan',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gunakan "Tulis manual" jika layanan ini belum terdaftar di katalog.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scroll,
                  itemCount: _services!.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = _services![i];
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(item),
                      borderRadius: AppRadius.card,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: AppRadius.card,
                          border: Border.all(
                            color: AppColors.borderStrong,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.pastelAmber,
                                borderRadius: AppRadius.sm,
                                border: Border.all(
                                  color: AppColors.borderStrong,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                AppIcons.wrench,
                                size: 18,
                                color: AppColors.ink900,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink900,
                                    ),
                                  ),
                                  if (item.code != null &&
                                      item.code!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.code!,
                                      style: AppTypography.mono(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rupiah(item.price),
                              style: AppTypography.chakra(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
