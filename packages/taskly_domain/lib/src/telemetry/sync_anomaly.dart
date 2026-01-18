import 'package:meta/meta.dart';

/// A typed diagnostic event emitted when the sync pipeline encounters a
/// divergence that may require developer attention.
///
/// These events are intended for logging/diagnostics. User-facing conflict UX
/// is handled separately (and is intentionally minimal in production).
@immutable
final class SyncAnomaly {
  const SyncAnomaly({
    required this.kind,
    required this.occurredAt,
    required this.table,
    required this.rowId,
    this.operation,
    this.reason,
    this.remoteCode,
    this.remoteMessage,
    this.correlationId,
    this.details,
  });

  /// High-level anomaly category.
  final SyncAnomalyKind kind;

  /// Local time when the anomaly was detected.
  final DateTime occurredAt;

  /// Remote table name associated with the failing sync operation.
  final String table;

  /// Row id associated with the failing sync operation.
  final String rowId;

  /// CRUD operation associated with the anomaly (e.g. "put", "patch", "delete").
  final String? operation;

  /// More specific reason/cause for the anomaly.
  final SyncAnomalyReason? reason;

  /// Remote error code (Postgres/PostgREST/etc) if available.
  final String? remoteCode;

  /// Remote error message if available.
  final String? remoteMessage;

  /// Optional correlation id that ties this anomaly back to a user action.
  ///
  /// This may be null if the sync pipeline cannot associate a queued CRUD
  /// operation with the original write context.
  final String? correlationId;

  /// Optional additional structured details (non-PII).
  final Map<String, Object?>? details;

  /// A concise, debug-friendly summary.
  String debugSummary({bool includeCorrelationId = true}) {
    final pieces = <String>[
      kind.name,
      '$table/$rowId',
      ?operation,
      if (reason != null) reason!.name,
      if (remoteCode != null) 'code=$remoteCode',
      if (includeCorrelationId && correlationId != null) 'cid=$correlationId',
    ];

    return pieces.join(' • ');
  }

  @override
  String toString() {
    return 'SyncAnomaly(kind=$kind, table=$table, rowId=$rowId, op=$operation, '
        'reason=$reason, remoteCode=$remoteCode, correlationId=$correlationId)';
  }
}

/// High-level anomaly category.
///
/// Mirrors DEC-063A naming intent.
enum SyncAnomalyKind {
  /// Supabase/PostgREST rejected an upload operation, but the local write was
  /// already applied to the offline-first DB.
  supabaseRejectedButLocalApplied,

  /// A conflict was detected and resolved (remote value chosen).
  conflictResolvedWithRemote,

  /// A conflict was detected and resolved (local value chosen).
  conflictResolvedWithLocal,
}

/// More specific reason/cause for a [SyncAnomaly].
enum SyncAnomalyReason {
  /// A deterministic-id (v5) natural key collision was detected (same natural
  /// key, different id).
  naturalKeyConflictDifferentId,

  /// A unique constraint violation occurred for a non-deterministic-id table
  /// (unexpected).
  unexpectedUniqueViolation,

  /// The server rejected the record due to a fatal/non-retryable response code.
  fatalRemoteRejection,

  /// The server schema cache did not contain the referenced table.
  schemaNotFound,
}

/// A contract for a stream of sync anomalies.
///
/// This is exposed across layers so that presentation can subscribe (via a
/// BLoC) without depending on data-layer implementations.
abstract interface class SyncAnomalyStream {
  Stream<SyncAnomaly> get anomalies;
}
