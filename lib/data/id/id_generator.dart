import 'package:uuid/uuid.dart';
import 'package:taskly_bloc/domain/models/label.dart' show LabelType;

/// Centralized ID generation for offline-first architecture.
///
/// Uses UUID v5 for entities with natural keys (deterministic - same inputs
/// produce same ID across devices) and UUID v4 for user content (random).
///
/// This class is the single source of truth for ID strategy per table,
/// used by repositories for generation and by uploadData for conflict handling.
class IdGenerator {
  IdGenerator(this._userId);

  final String _userId;
  static const _uuid = Uuid();

  /// UUID v5 namespace for deterministic ID generation.
  static const _v5Namespace = 'https://taskly.app';

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLE STRATEGY REGISTRY - Single Source of Truth
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tables using UUID v5 (deterministic from natural key).
  /// 23505 errors on these tables may indicate expected duplicates.
  static const Set<String> v5Tables = {
    'labels',
    'trackers',
    'task_labels',
    'project_labels',
    'task_completion_history',
    'project_completion_history',
    'task_recurrence_exceptions',
    'project_recurrence_exceptions',
    'tracker_responses',
    'daily_tracker_responses',
    'screen_definitions',
    'workflow_definitions',
    'analytics_snapshots',
  };

  /// Tables using UUID v4 (random - user content with no natural key).
  static const Set<String> v4Tables = {
    'tasks',
    'projects',
    'journal_entries',
    'workflows',
    'user_profiles',
    'pending_notifications',
    'analytics_correlations',
    'analytics_insights',
  };

  /// Check if a table uses deterministic v5 IDs.
  /// Used by uploadData to apply smart 23505 conflict handling.
  static bool isDeterministic(String tableName) => v5Tables.contains(tableName);

  /// Check if a table uses random v4 IDs.
  static bool isRandom(String tableName) => v4Tables.contains(tableName);

  /// Get the current user ID (for debugging/logging).
  String get userId => _userId;

  // ═══════════════════════════════════════════════════════════════════════════
  // V4 RANDOM IDs - User Content (no natural key)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate random ID for a new task.
  String taskId() => _uuid.v4();

  /// Generate random ID for a new project.
  String projectId() => _uuid.v4();

  /// Generate random ID for a new journal entry.
  String journalEntryId() => _uuid.v4();

  /// Generate random ID for a workflow run instance.
  String workflowRunId() => _uuid.v4();

  /// Generate random ID for user profile.
  String userProfileId() => _uuid.v4();

  /// Generate random ID for pending notification.
  String pendingNotificationId() => _uuid.v4();

  /// Generate random ID for analytics correlation.
  String analyticsCorrelationId() => _uuid.v4();

  /// Generate random ID for analytics insight.
  String analyticsInsightId() => _uuid.v4();

  // ═══════════════════════════════════════════════════════════════════════════
  // V5 DETERMINISTIC IDs - Natural Key → Same ID
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate deterministic ID for a label.
  /// Natural key: userId + name + type
  String labelId({required String name, required LabelType type}) {
    return _v5('labels/$name/${type.name}');
  }

  /// Generate deterministic ID for a tracker.
  /// Natural key: userId + name
  String trackerId({required String name}) {
    return _v5('trackers/$name');
  }

  /// Generate deterministic ID for task-label junction.
  /// Natural key: taskId + labelId
  String taskLabelId({required String taskId, required String labelId}) {
    // Note: No userId in path - taskId already scopes to user
    return _v5NoUser('task_labels/$taskId/$labelId');
  }

  /// Generate deterministic ID for project-label junction.
  /// Natural key: projectId + labelId
  String projectLabelId({required String projectId, required String labelId}) {
    return _v5NoUser('project_labels/$projectId/$labelId');
  }

  /// Generate deterministic ID for task completion history.
  /// Natural key: taskId + occurrenceDate (null for non-repeating)
  String taskCompletionId({
    required String taskId,
    required DateTime? occurrenceDate,
  }) {
    final dateKey =
        occurrenceDate?.toIso8601String().split('T').first ?? 'null';
    return _v5NoUser('task_completion/$taskId/$dateKey');
  }

  /// Generate deterministic ID for project completion history.
  /// Natural key: projectId + occurrenceDate (null for non-repeating)
  String projectCompletionId({
    required String projectId,
    required DateTime? occurrenceDate,
  }) {
    final dateKey =
        occurrenceDate?.toIso8601String().split('T').first ?? 'null';
    return _v5NoUser('project_completion/$projectId/$dateKey');
  }

  /// Generate deterministic ID for task recurrence exception.
  /// Natural key: taskId + originalDate
  String taskRecurrenceExceptionId({
    required String taskId,
    required DateTime originalDate,
  }) {
    final dateKey = originalDate.toIso8601String().split('T').first;
    return _v5NoUser('task_exception/$taskId/$dateKey');
  }

  /// Generate deterministic ID for project recurrence exception.
  /// Natural key: projectId + originalDate
  String projectRecurrenceExceptionId({
    required String projectId,
    required DateTime originalDate,
  }) {
    final dateKey = originalDate.toIso8601String().split('T').first;
    return _v5NoUser('project_exception/$projectId/$dateKey');
  }

  /// Generate deterministic ID for tracker response (per-entry).
  /// Natural key: journalEntryId + trackerId
  String trackerResponseId({
    required String journalEntryId,
    required String trackerId,
  }) {
    return _v5NoUser('tracker_response/$journalEntryId/$trackerId');
  }

  /// Generate deterministic ID for daily tracker response.
  /// Natural key: userId + trackerId + responseDate
  String dailyTrackerResponseId({
    required String trackerId,
    required DateTime responseDate,
  }) {
    final dateKey = responseDate.toIso8601String().split('T').first;
    return _v5('daily_tracker/$trackerId/$dateKey');
  }

  /// Generate deterministic ID for screen definition.
  /// Natural key: userId + screenKey
  String screenDefinitionId({required String screenKey}) {
    return _v5('screens/$screenKey');
  }

  /// Generate deterministic ID for workflow definition.
  /// Natural key: userId + name (normalized as key)
  String workflowDefinitionId({required String name}) {
    // Normalize name to create stable key: lowercase, replace spaces with dashes
    final normalizedKey = name.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      '-',
    );
    return _v5('workflows/$normalizedKey');
  }

  /// Generate deterministic ID for analytics snapshot.
  /// Natural key: userId + entityType + entityId + snapshotDate
  String analyticsSnapshotId({
    required String entityType,
    required String entityId,
    required DateTime snapshotDate,
  }) {
    final dateKey = snapshotDate.toIso8601String().split('T').first;
    return _v5('analytics_snapshot/$entityType/$entityId/$dateKey');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate v5 UUID with userId prefix (for user-scoped entities).
  String _v5(String path) {
    return _uuid.v5(Namespace.url.value, '$_v5Namespace/$_userId/$path');
  }

  /// Generate v5 UUID without userId prefix (for entities scoped by parent ID).
  String _v5NoUser(String path) {
    return _uuid.v5(Namespace.url.value, '$_v5Namespace/$path');
  }
}
