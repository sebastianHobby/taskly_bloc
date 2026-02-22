import 'package:meta/meta.dart';

enum SyncIssueStatus { open, resolved, ignored }

enum SyncIssueSeverity { info, warning, error, critical }

enum SyncIssueCategory {
  validation,
  conflict,
  auth,
  schema,
  transport,
  pipeline,
}

@immutable
final class SyncIssue {
  const SyncIssue({
    required this.id,
    required this.userId,
    required this.status,
    required this.severity,
    required this.category,
    required this.fingerprint,
    required this.issueCode,
    required this.title,
    required this.message,
    required this.details,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.occurrenceCount,
    required this.createdAt,
    required this.updatedAt,
    this.correlationId,
    this.syncSessionId,
    this.clientId,
    this.operation,
    this.entityType,
    this.entityId,
    this.remoteCode,
    this.remoteMessage,
    this.resolvedAt,
  });

  final String id;
  final String userId;
  final SyncIssueStatus status;
  final SyncIssueSeverity severity;
  final SyncIssueCategory category;
  final String fingerprint;
  final String issueCode;
  final String title;
  final String message;
  final String? correlationId;
  final String? syncSessionId;
  final String? clientId;
  final String? operation;
  final String? entityType;
  final String? entityId;
  final String? remoteCode;
  final String? remoteMessage;
  final Map<String, Object?> details;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int occurrenceCount;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
