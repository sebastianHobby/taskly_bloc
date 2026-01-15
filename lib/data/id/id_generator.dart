import 'package:uuid/uuid.dart';

/// Factory function that returns the current user ID.
/// Throws [StateError] if no user is authenticated.
typedef UserIdGetter = String Function();

/// Centralized ID generation for offline-first architecture.
///
/// Uses UUID v5 for entities with natural keys (deterministic - same inputs
/// produce same ID across devices) and UUID v4 for user content (random).
///
/// This class is the single source of truth for ID strategy per table,
/// used by repositories for generation and by uploadData for conflict handling.
///
/// The [IdGenerator] uses lazy evaluation for the user ID, meaning it only
/// requires an authenticated user when generating IDs that need the user ID
/// (v5 deterministic IDs), not at construction time.
class IdGenerator {
  /// Creates an IdGenerator with a lazy user ID getter.
  ///
  /// The [userIdGetter] is called only when generating IDs that require
  /// the user ID. This allows repositories to be constructed before
  /// authentication is complete.
  IdGenerator(this._userIdGetter);

  /// Creates an IdGenerator with a fixed user ID (for testing/backwards compat).
  IdGenerator.withUserId(String userId) : _userIdGetter = (() => userId);

  final UserIdGetter _userIdGetter;
  static const _uuid = Uuid();

  /// UUID v5 namespace for deterministic ID generation.
  static const _v5Namespace = 'https://taskly.app';

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLE STRATEGY REGISTRY - Single Source of Truth
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tables using UUID v5 (deterministic from natural key).
  /// 23505 errors on these tables may indicate expected duplicates.
  static const Set<String> v5Tables = {
    'values',
    'task_values',
    'project_values',
    'task_completion_history',
    'project_completion_history',
    'task_recurrence_exceptions',
    'project_recurrence_exceptions',
    'tracker_definitions',
    'tracker_preferences',
    'tracker_definition_choices',
    'analytics_snapshots',
    'attention_rules',
  };

  /// Tables using UUID v4 (random - user content with no natural key).
  static const Set<String> v4Tables = {
    'tasks',
    'projects',
    'journal_entries',
    'user_profiles',
    'pending_notifications',
    'analytics_correlations',
    'analytics_insights',
    'attention_resolutions',
  };

  /// Check if a table uses deterministic v5 IDs.
  /// Used by uploadData to apply smart 23505 conflict handling.
  static bool isDeterministic(String tableName) => v5Tables.contains(tableName);

  /// Check if a table uses random v4 IDs.
  static bool isRandom(String tableName) => v4Tables.contains(tableName);

  /// Get the current user ID.
  ///
  /// Throws [StateError] if no user is authenticated.
  String get userId => _userIdGetter();

  // ═══════════════════════════════════════════════════════════════════════════
  // V4 RANDOM IDs - User Content (no natural key)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate random ID for a new task.
  String taskId() => _uuid.v4();

  /// Generate random ID for a new project.
  String projectId() => _uuid.v4();

  /// Generate random ID for a new journal entry.
  String journalEntryId() => _uuid.v4();

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

  /// Generate deterministic ID for a value.
  /// Natural key: userId + name
  String valueId({required String name}) {
    return _v5('values/$name');
  }

  /// Generate deterministic ID for a tracker definition.
  /// Natural key: userId + name
  String trackerDefinitionId({required String name}) {
    return _v5('tracker_definitions/$name');
  }

  /// Generate deterministic ID for tracker preferences.
  /// Natural key: userId + trackerId
  String trackerPreferenceId({required String trackerId}) {
    return _v5('tracker_preferences/$trackerId');
  }

  /// Generate deterministic ID for tracker definition choices.
  /// Natural key: userId + trackerId + choiceKey
  String trackerDefinitionChoiceId({
    required String trackerId,
    required String choiceKey,
  }) {
    return _v5('tracker_definition_choices/$trackerId/$choiceKey');
  }

  /// Generate deterministic ID for task-value junction.
  /// Natural key: taskId + valueId
  String taskValueId({required String taskId, required String valueId}) {
    // Note: No userId in path - taskId already scopes to user
    return _v5NoUser('task_values/$taskId/$valueId');
  }

  /// Generate deterministic ID for project-value junction.
  /// Natural key: projectId + valueId
  String projectValueId({required String projectId, required String valueId}) {
    return _v5NoUser('project_values/$projectId/$valueId');
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

  /// Generate random ID for a tracker event (append-only).
  String trackerEventId() => _uuid.v4();

  /// Generate deterministic ID for screen preferences.
  /// Natural key: userId + screenKey
  String screenDefinitionId({required String screenKey}) {
    return _v5('screens/$screenKey');
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

  /// Generate deterministic ID for attention rule.
  /// Natural key: userId + ruleKey
  String attentionRuleId({required String ruleKey}) {
    return _v5('attention_rules/$ruleKey');
  }

  /// Generate random ID for attention resolution.
  String attentionResolutionId() => _uuid.v4();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate v5 UUID with userId prefix (for user-scoped entities).
  ///
  /// Throws [StateError] if no user is authenticated.
  String _v5(String path) {
    final currentUserId = _userIdGetter();
    return _uuid.v5(Namespace.url.value, '$_v5Namespace/$currentUserId/$path');
  }

  /// Generate v5 UUID without userId prefix (for entities scoped by parent ID).
  String _v5NoUser(String path) {
    return _uuid.v5(Namespace.url.value, '$_v5Namespace/$path');
  }
}
