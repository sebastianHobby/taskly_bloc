import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

class SyncIssueRepository implements SyncIssueRepositoryContract {
  SyncIssueRepository({
    required supabase.SupabaseClient client,
    Clock clock = systemClock,
  }) : _client = client,
       _clock = clock;

  final supabase.SupabaseClient _client;
  final Clock _clock;

  @override
  Future<void> recordAnomaly(SyncAnomaly anomaly) async {
    final issueCode = anomaly.reason?.name ?? anomaly.kind.name;
    final category = _mapCategory(anomaly);
    final severity = _mapSeverity(anomaly);
    final fingerprint = _buildFingerprint(anomaly, issueCode: issueCode);

    final details = <String, Object?>{
      ...?anomaly.details,
      'kind': anomaly.kind.name,
      'reason': anomaly.reason?.name,
      'occurred_at': anomaly.occurredAt.toUtc().toIso8601String(),
    }..removeWhere((_, value) => value == null);

    final title = 'Sync anomaly: ${anomaly.kind.name}';
    final message = anomaly.debugSummary();

    try {
      await _client.rpc<Object?>(
        'record_sync_issue',
        params: <String, Object?>{
          'p_status': SyncIssueStatus.open.name,
          'p_severity': severity.name,
          'p_category': category.name,
          'p_fingerprint': fingerprint,
          'p_issue_code': issueCode,
          'p_title': title,
          'p_message': message,
          'p_correlation_id': anomaly.correlationId,
          'p_sync_session_id': _stringDetail(details, 'syncSessionId'),
          'p_client_id': _stringDetail(details, 'clientId'),
          'p_operation': anomaly.operation,
          'p_entity_type': _stringDetail(details, 'entityType'),
          'p_entity_id': anomaly.rowId,
          'p_remote_code': anomaly.remoteCode,
          'p_remote_message': anomaly.remoteMessage,
          'p_details': details,
          'p_seen_at': _clock.nowUtc().toIso8601String(),
        },
      );
    } catch (error, stackTrace) {
      AppLog.handleStructured(
        'sync',
        'sync.issue.record.failed',
        error,
        stackTrace,
        <String, Object?>{
          'issue_code': issueCode,
          'table': anomaly.table,
          'row_id': anomaly.rowId,
          'operation': anomaly.operation,
          'correlation_id': anomaly.correlationId,
        },
      );
    }
  }

  @override
  Future<List<SyncIssue>> fetchOpen({int limit = 100}) async {
    final rows = await _client
        .from('sync_issues')
        .select()
        .eq('status', SyncIssueStatus.open.name)
        .order('last_seen_at', ascending: false)
        .limit(limit);

    final list = (rows as List).whereType<Map<String, dynamic>>().toList();
    return list.map(_mapIssue).toList(growable: false);
  }

  static SyncIssueCategory _mapCategory(SyncAnomaly anomaly) {
    return switch (anomaly.reason) {
      SyncAnomalyReason.schemaNotFound => SyncIssueCategory.schema,
      SyncAnomalyReason.naturalKeyConflictDifferentId ||
      SyncAnomalyReason.unexpectedUniqueViolation => SyncIssueCategory.conflict,
      SyncAnomalyReason.fatalRemoteRejection => SyncIssueCategory.validation,
      SyncAnomalyReason.uploadLoopDetected ||
      SyncAnomalyReason.uploadReentrancy ||
      SyncAnomalyReason.missingOperationContext ||
      SyncAnomalyReason.missingCrudPayload => SyncIssueCategory.pipeline,
      null => switch (anomaly.kind) {
        SyncAnomalyKind.syncPipelineIssue => SyncIssueCategory.pipeline,
        SyncAnomalyKind.supabaseRejectedButLocalApplied =>
          SyncIssueCategory.validation,
        SyncAnomalyKind.conflictResolvedWithRemote ||
        SyncAnomalyKind.conflictResolvedWithLocal => SyncIssueCategory.conflict,
      },
    };
  }

  static SyncIssueSeverity _mapSeverity(SyncAnomaly anomaly) {
    return switch (anomaly.kind) {
      SyncAnomalyKind.syncPipelineIssue => SyncIssueSeverity.warning,
      SyncAnomalyKind.supabaseRejectedButLocalApplied =>
        SyncIssueSeverity.error,
      SyncAnomalyKind.conflictResolvedWithRemote ||
      SyncAnomalyKind.conflictResolvedWithLocal => SyncIssueSeverity.info,
    };
  }

  static String _buildFingerprint(
    SyncAnomaly anomaly, {
    required String issueCode,
  }) {
    final parts = <String>[
      anomaly.kind.name,
      anomaly.reason?.name ?? 'none',
      anomaly.table,
      anomaly.rowId,
      anomaly.operation ?? 'none',
      anomaly.remoteCode ?? 'none',
      issueCode,
    ];
    final value = parts.join('|').toLowerCase();
    return value.length <= 512 ? value : value.substring(0, 512);
  }

  static String? _stringDetail(Map<String, Object?> details, String key) {
    final value = details[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static SyncIssue _mapIssue(Map<String, dynamic> row) {
    DateTime parseDate(String key) {
      final raw = row[key];
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed.toUtc();
      }
      throw StateError('sync_issues.$key is missing/invalid.');
    }

    DateTime? parseDateOrNull(String key) {
      final raw = row[key];
      if (raw is! String || raw.trim().isEmpty) return null;
      return DateTime.tryParse(raw)?.toUtc();
    }

    SyncIssueStatus parseStatus(Object? raw) {
      return SyncIssueStatus.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => SyncIssueStatus.open,
      );
    }

    SyncIssueSeverity parseSeverity(Object? raw) {
      return SyncIssueSeverity.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => SyncIssueSeverity.error,
      );
    }

    SyncIssueCategory parseCategory(Object? raw) {
      return SyncIssueCategory.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => SyncIssueCategory.pipeline,
      );
    }

    final detailsRaw = row['details'];
    final details = detailsRaw is Map<String, dynamic>
        ? Map<String, Object?>.from(detailsRaw)
        : <String, Object?>{};

    return SyncIssue(
      id: '${row['id']}',
      userId: '${row['user_id']}',
      status: parseStatus(row['status']),
      severity: parseSeverity(row['severity']),
      category: parseCategory(row['category']),
      fingerprint: '${row['fingerprint']}',
      issueCode: '${row['issue_code']}',
      title: '${row['title']}',
      message: '${row['message']}',
      correlationId: row['correlation_id'] as String?,
      syncSessionId: row['sync_session_id'] as String?,
      clientId: row['client_id'] as String?,
      operation: row['operation'] as String?,
      entityType: row['entity_type'] as String?,
      entityId: row['entity_id'] as String?,
      remoteCode: row['remote_code'] as String?,
      remoteMessage: row['remote_message'] as String?,
      details: details,
      firstSeenAt: parseDate('first_seen_at'),
      lastSeenAt: parseDate('last_seen_at'),
      occurrenceCount: (row['occurrence_count'] as num?)?.toInt() ?? 1,
      resolvedAt: parseDateOrNull('resolved_at'),
      createdAt: parseDate('created_at'),
      updatedAt: parseDate('updated_at'),
    );
  }
}
