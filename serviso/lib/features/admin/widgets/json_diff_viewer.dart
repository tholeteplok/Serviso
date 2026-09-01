import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class JsonDiffViewer extends StatelessWidget {
  const JsonDiffViewer({
    super.key,
    this.oldData,
    this.newData,
  });

  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;

  @override
  Widget build(BuildContext context) {
    if (oldData == null && newData == null) {
      return Text(
        'Tanpa data tambahan',
        style: AppTypography.textTheme().bodyMedium?.copyWith(
              color: AppColors.inkMuted,
              fontStyle: FontStyle.italic,
            ),
      );
    }

    final allKeys = <String>{
      ...?oldData?.keys,
      ...?newData?.keys,
    }.toList()
      ..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allKeys.map((key) {
          final hasOld = oldData != null && oldData!.containsKey(key);
          final hasNew = newData != null && newData!.containsKey(key);
          final oldVal = oldData?[key];
          final newVal = newData?[key];

          if (!hasOld && hasNew) {
            // Added key (Green)
            return _buildLine(
              key: '+ $key',
              val: _formatValue(newVal),
              bgColor: AppColors.tintTeal,
              textColor: AppColors.teal,
            );
          } else if (hasOld && !hasNew) {
            // Deleted key (Red)
            return _buildLine(
              key: '- $key',
              val: _formatValue(oldVal),
              bgColor: AppColors.tintAction,
              textColor: AppColors.action,
            );
          } else if (oldVal != newVal) {
            // Modified key (Yellow/Orange)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLine(
                  key: '- $key',
                  val: _formatValue(oldVal),
                  bgColor: AppColors.tintAction,
                  textColor: AppColors.action,
                ),
                _buildLine(
                  key: '+ $key',
                  val: _formatValue(newVal),
                  bgColor: AppColors.tintTeal,
                  textColor: AppColors.teal,
                ),
              ],
            );
          } else {
            // Unchanged key (Neutral)
            return _buildLine(
              key: '  $key',
              val: _formatValue(newVal),
              bgColor: Colors.transparent,
              textColor: AppColors.inkMuted,
            );
          }
        }).toList(),
      ),
    );
  }

  String _formatValue(dynamic val) {
    if (val == null) return 'null';
    if (val is Map || val is List) return jsonEncode(val);
    return val.toString();
  }

  Widget _buildLine({
    required String key,
    required String val,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTypography.mono(fontSize: 12, color: textColor),
          children: [
            TextSpan(
              text: '$key: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: val),
          ],
        ),
      ),
    );
  }
}
