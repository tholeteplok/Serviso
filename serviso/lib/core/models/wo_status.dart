import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum WoStatus { menunggu, dikerjakan, selesai, dibatalkan }

extension WoStatusX on WoStatus {
  String get label => switch (this) {
        WoStatus.menunggu => 'Menunggu',
        WoStatus.dikerjakan => 'Dikerjakan',
        WoStatus.selesai => 'Selesai',
        WoStatus.dibatalkan => 'Dibatalkan',
      };

  Color get accentColor => switch (this) {
        WoStatus.menunggu => AppColors.inkMuted,
        WoStatus.dikerjakan => AppColors.teal,
        WoStatus.selesai => AppColors.primary,
        WoStatus.dibatalkan => AppColors.action,
      };

  Color get bgColor => AppColors.tintOf(accentColor);
}
