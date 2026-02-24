import 'package:taskly_data/id.dart';

/// Fake IdGenerator for predictable ID generation in tests.
///
/// Generates sequential IDs for v4 methods (task-0, task-1, etc.)
/// and deterministic IDs for v5 methods based on input parameters.
///
/// Usage:
/// ```dart
/// final idGenerator = FakeIdGenerator();
/// final taskId1 = idGenerator.taskId(); // 'task-0'
/// final taskId2 = idGenerator.taskId(); // 'task-1'
///
/// // Verify method calls
/// expect(idGenerator.taskIdCallCount, 2);
///
/// // Reset for next test
/// idGenerator.reset();
/// ```
class FakeIdGenerator implements IdGenerator {
  FakeIdGenerator([this._userId = 'test-user']);

  final String _userId;

  // Call counters for verification
  int _taskIdCounter = 0;
  int _projectIdCounter = 0;
  int _journalEntryIdCounter = 0;
  int _userProfileIdCounter = 0;
  int _pendingNotificationIdCounter = 0;
  int _analyticsCorrelationIdCounter = 0;
  int _analyticsInsightIdCounter = 0;
  int _trackerEventIdCounter = 0;
  int _trackerGroupIdCounter = 0;
  int _taskSnoozeEventIdCounter = 0;
  int _routineIdCounter = 0;
  int _routineCompletionIdCounter = 0;
  int _routineSkipIdCounter = 0;
  int _taskChecklistItemIdCounter = 0;
  int _routineChecklistItemIdCounter = 0;
  int _checklistEventIdCounter = 0;
  int _syncIssueIdCounter = 0;
  int _myDayDecisionEventIdCounter = 0;

  // Call counts for verification
  int get taskIdCallCount => _taskIdCounter;
  int get projectIdCallCount => _projectIdCounter;
  int get journalEntryIdCallCount => _journalEntryIdCounter;

  @override
  String get userId => _userId;

  // ═══════════════════════════════════════════════════════════════════════════
  // V4 RANDOM IDs - Sequential for predictability
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String taskId() => 'task-${_taskIdCounter++}';

  @override
  String projectId() => 'project-${_projectIdCounter++}';

  @override
  String journalEntryId() => 'journal-${_journalEntryIdCounter++}';

  @override
  String userProfileId() => 'user-profile-${_userProfileIdCounter++}';

  @override
  String pendingNotificationId() =>
      'notification-${_pendingNotificationIdCounter++}';

  @override
  String analyticsCorrelationId() =>
      'correlation-${_analyticsCorrelationIdCounter++}';

  @override
  String analyticsInsightId() => 'insight-${_analyticsInsightIdCounter++}';

  @override
  String trackerGroupId() => 'tracker-group-${_trackerGroupIdCounter++}';

  @override
  String taskSnoozeEventId() => 'task-snooze-${_taskSnoozeEventIdCounter++}';

  @override
  String routineId() => 'routine-${_routineIdCounter++}';

  @override
  String routineCompletionId() =>
      'routine-completion-${_routineCompletionIdCounter++}';

  @override
  String routineSkipId() => 'routine-skip-${_routineSkipIdCounter++}';

  @override
  String taskChecklistItemId() =>
      'task-checklist-item-${_taskChecklistItemIdCounter++}';

  @override
  String routineChecklistItemId() =>
      'routine-checklist-item-${_routineChecklistItemIdCounter++}';

  @override
  String checklistEventId() => 'checklist-event-${_checklistEventIdCounter++}';

  @override
  String syncIssueId() => 'sync-issue-${_syncIssueIdCounter++}';

  @override
  String myDayDecisionEventId() =>
      'my-day-decision-event-${_myDayDecisionEventIdCounter++}';

  // ═══════════════════════════════════════════════════════════════════════════
  // V5 DETERMINISTIC IDs - Predictable based on inputs
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String valueId({required String name}) =>
      'value-${name.toLowerCase().replaceAll(' ', '-')}';

  @override
  String trackerDefinitionId({required String name}) =>
      'tracker-def-${name.toLowerCase().replaceAll(' ', '-')}';

  @override
  String trackerPreferenceId({required String trackerId}) =>
      'tracker-pref-$trackerId';

  @override
  String trackerDefinitionChoiceId({
    required String trackerId,
    required String choiceKey,
  }) => 'tracker-choice-$trackerId-$choiceKey';

  @override
  String taskCompletionId({
    required String taskId,
    required DateTime? occurrenceDate,
  }) {
    final dateKey =
        occurrenceDate?.toIso8601String().split('T').first ?? 'null';
    return 'task-completion-$taskId-$dateKey';
  }

  @override
  String projectCompletionId({
    required String projectId,
    required DateTime? occurrenceDate,
  }) {
    final dateKey =
        occurrenceDate?.toIso8601String().split('T').first ?? 'null';
    return 'project-completion-$projectId-$dateKey';
  }

  @override
  String taskRecurrenceExceptionId({
    required String taskId,
    required DateTime originalDate,
  }) {
    final dateKey = originalDate.toIso8601String().split('T').first;
    return 'task-exception-$taskId-$dateKey';
  }

  @override
  String projectRecurrenceExceptionId({
    required String projectId,
    required DateTime originalDate,
  }) {
    final dateKey = originalDate.toIso8601String().split('T').first;
    return 'project-exception-$projectId-$dateKey';
  }

  @override
  String trackerEventId() => 'tracker-event-${_trackerEventIdCounter++}';

  @override
  String screenDefinitionId({required String screenKey}) => 'screen-$screenKey';

  @override
  String analyticsSnapshotId({
    required String entityType,
    required String entityId,
    required DateTime snapshotDate,
  }) {
    final dateKey = snapshotDate.toIso8601String().split('T').first;
    return 'snapshot-$entityType-$entityId-$dateKey';
  }

  @override
  String myDayDayId({required DateTime dayUtc}) {
    final dateKey = dayUtc.toIso8601String().split('T').first;
    return 'my-day-day-$dateKey';
  }

  @override
  String myDayPickId({
    required String dayId,
    required String targetType,
    required String targetId,
  }) {
    return 'my-day-pick-$dayId-$targetType-$targetId';
  }

  @override
  String valueWeeklyRatingId({
    required String valueId,
    required DateTime weekStartUtc,
  }) {
    final dateKey = weekStartUtc.toIso8601String().split('T').first;
    return 'value-weekly-$valueId-$dateKey';
  }

  @override
  String attentionRuleId({required String ruleKey}) =>
      'attention-rule-${ruleKey.toLowerCase().replaceAll('_', '-')}';

  @override
  String projectAnchorStateIdForProject({required String projectId}) =>
      'project-anchor-$projectId';

  @override
  String taskChecklistItemStateId({
    required String taskId,
    required String checklistItemId,
    required DateTime? occurrenceDate,
  }) {
    final dateKey =
        occurrenceDate?.toIso8601String().split('T').first ?? 'null';
    return 'task-checklist-state-$taskId-$checklistItemId-$dateKey';
  }

  @override
  String routineChecklistItemStateId({
    required String routineId,
    required String checklistItemId,
    required String periodType,
    required DateTime windowKey,
  }) {
    final dateKey = windowKey.toIso8601String().split('T').first;
    return 'routine-checklist-state-$routineId-$checklistItemId-$periodType-$dateKey';
  }

  @override
  String attentionResolutionId() =>
      'attention-resolution-${_attentionResolutionIdCounter++}';

  int _attentionResolutionIdCounter = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Test Utilities
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reset all counters for fresh test state.
  void reset() {
    _taskIdCounter = 0;
    _projectIdCounter = 0;
    _journalEntryIdCounter = 0;
    _userProfileIdCounter = 0;
    _pendingNotificationIdCounter = 0;
    _analyticsCorrelationIdCounter = 0;
    _analyticsInsightIdCounter = 0;
    _trackerEventIdCounter = 0;
    _attentionResolutionIdCounter = 0;
    _taskSnoozeEventIdCounter = 0;
    _routineIdCounter = 0;
    _routineCompletionIdCounter = 0;
    _routineSkipIdCounter = 0;
    _taskChecklistItemIdCounter = 0;
    _routineChecklistItemIdCounter = 0;
    _checklistEventIdCounter = 0;
    _syncIssueIdCounter = 0;
    _myDayDecisionEventIdCounter = 0;
  }

  /// Get the next task ID without incrementing the counter.
  /// Useful for assertions.
  String peekNextTaskId() => 'task-$_taskIdCounter';

  /// Get the next project ID without incrementing the counter.
  String peekNextProjectId() => 'project-$_projectIdCounter';
}
