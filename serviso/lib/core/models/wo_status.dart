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
        WoStatus.menunggu => AppColors.statusWaiting,
        WoStatus.dikerjakan => AppColors.statusProgress,
        WoStatus.selesai => AppColors.statusDone,
        WoStatus.dibatalkan => AppColors.statusCancelled,
      };

  Color get bgColor => accentColor;

  Color get textColor => switch (this) {
        WoStatus.menunggu => AppColors.borderStrong,
        WoStatus.dikerjakan => Colors.white,
        WoStatus.selesai => Colors.white,
        WoStatus.dibatalkan => Colors.white,
      };
}
