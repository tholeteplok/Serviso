import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum UserPresenceStatus { online, idle, offline }

abstract final class UserPresenceHelper {
  static ({UserPresenceStatus status, String label, Color color}) getPresence({
    required DateTime? lastSeenAt,
    required bool isActive,
  }) {
    if (!isActive || lastSeenAt == null) {
      return (
        status: UserPresenceStatus.offline,
        label: 'Offline',
        color: AppColors.inkMuted,
      );
    }

    final now = DateTime.now();
    final diff = now.difference(lastSeenAt);

    if (diff.isNegative || diff.inMinutes < 3) {
      return (
        status: UserPresenceStatus.online,
        label: 'Online',
        color: AppColors.teal,
      );
    } else if (diff.inMinutes < 15) {
      final mins = diff.inMinutes == 0 ? 1 : diff.inMinutes;
      return (
        status: UserPresenceStatus.idle,
        label: 'Idle · ${mins}m lalu',
        color: AppColors.amber,
      );
    } else {
      final isToday = now.year == lastSeenAt.year &&
          now.month == lastSeenAt.month &&
          now.day == lastSeenAt.day;
      final timeStr =
          '${lastSeenAt.hour.toString().padLeft(2, '0')}:${lastSeenAt.minute.toString().padLeft(2, '0')}';
      final label = isToday ? 'Hari ini $timeStr' : '${lastSeenAt.day}/${lastSeenAt.month} $timeStr';
      return (
        status: UserPresenceStatus.offline,
        label: 'Offline · $label',
        color: AppColors.inkMuted,
      );
    }
  }
}

/// Indikator dot bundar Neo-Brutalist untuk ditempatkan pada sudut avatar.
class UserPresenceDot extends StatelessWidget {
  const UserPresenceDot({
    super.key,
    required this.status,
    required this.color,
    this.size = 12.0,
  });

  final UserPresenceStatus status;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('presence_dot_${status.name}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: AppColors.borderInk,
          width: 1.5,
        ),
      ),
    );
  }
}

/// Label keterangan presensi real-time untuk ditampilkan di samping/bawah nama user.
class UserPresenceLabel extends StatelessWidget {
  const UserPresenceLabel({
    super.key,
    required this.lastSeenAt,
    required this.isActive,
  });

  final DateTime? lastSeenAt;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final presence = UserPresenceHelper.getPresence(
      lastSeenAt: lastSeenAt,
      isActive: isActive,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: presence.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          presence.label,
          style: AppTypography.textTheme().bodySmall?.copyWith(
                color: presence.color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
