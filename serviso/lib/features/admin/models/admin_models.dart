import '../../../features/auth/models/profile.dart';

class AuditLogEntry {
  final int id;
  final String? actorId;
  final String actorName;
  final String action;
  final String tableName;
  final String recordId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    this.actorId,
    required this.actorName,
    required this.action,
    required this.tableName,
    required this.recordId,
    this.oldData,
    this.newData,
    required this.createdAt,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    String actor = 'Sistem';
    if (map['profiles'] != null && map['profiles']['full_name'] != null) {
      actor = map['profiles']['full_name'] as String;
    } else if (map['actor_id'] != null) {
      actor = (map['actor_id'] as String).substring(0, 8);
    }

    return AuditLogEntry(
      id: (map['id'] as num).toInt(),
      actorId: map['actor_id'] as String?,
      actorName: actor,
      action: map['action'] as String? ?? 'update',
      tableName: map['table_name'] as String? ?? '',
      recordId: map['record_id'] as String? ?? '',
      oldData: map['old_data'] != null
          ? Map<String, dynamic>.from(map['old_data'] as Map)
          : null,
      newData: map['new_data'] != null
          ? Map<String, dynamic>.from(map['new_data'] as Map)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }
}

class AuditLogFilter {
  final String? tableName;
  final String? action;
  final String? actorId;
  final DateTime? startDate;
  final DateTime? endDate;

  const AuditLogFilter({
    this.tableName,
    this.action,
    this.actorId,
    this.startDate,
    this.endDate,
  });

  AuditLogFilter copyWith({
    String? tableName,
    String? action,
    String? actorId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AuditLogFilter(
      tableName: tableName ?? this.tableName,
      action: action ?? this.action,
      actorId: actorId ?? this.actorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class CreateUserPayload {
  final String username;
  final String? email;
  final String fullName;
  final UserRole role;

  const CreateUserPayload({
    required this.username,
    this.email,
    required this.fullName,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': 'create',
      'username': username.trim().toLowerCase(),
      'email': email?.trim(),
      'full_name': fullName.trim(),
      'role': role.name,
    };
  }
}
