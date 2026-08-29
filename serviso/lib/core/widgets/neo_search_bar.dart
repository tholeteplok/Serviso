import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';

/// Tactile Pop-Brutalist SearchBar with 1.5px black border,
/// hard pop shadow, and scanner integration.
class NeoSearchBar extends StatelessWidget {
  const NeoSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onScanTap,
    this.onClear,
    this.hintText = 'Cari nama atau kode...',
    this.focusNode,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onScanTap;
  final VoidCallback? onClear;
  final String hintText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.borderStrong,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.borderStrong,
            offset: Offset(0, 3),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.search,
            color: AppColors.ink900,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: const TextStyle(
                color: AppColors.ink900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (onScanTap != null) ...[
            IconButton(
              icon: Icon(
                PhosphorIcons.barcode(PhosphorIconsStyle.bold),
                color: AppColors.ink900,
                size: 22,
              ),
              tooltip: 'Scan Barcode',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onScanTap,
            ),
            const SizedBox(width: 8),
          ],
          if (onClear != null && controller != null && controller!.text.isNotEmpty)
            IconButton(
              icon: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.bold),
                color: AppColors.ink900,
                size: 18,
              ),
              tooltip: 'Hapus',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}
