import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/models/label.dart' show LabelType;

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
  int _workflowRunIdCounter = 0;
  int _userProfileIdCounter = 0;
  int _pendingNotificationIdCounter = 0;
  int _analyticsCorrelationIdCounter = 0;
  int _analyticsInsightIdCounter = 0;

  // Call counts for verification
  int get taskIdCallCount => _taskIdCounter;
  int get projectIdCallCount => _projectIdCounter;
  int get journalEntryIdCallCount => _journalEntryIdCounter;
  int get workflowRunIdCallCount => _workflowRunIdCounter;

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
  String workflowRunId() => 'workflow-run-${_workflowRunIdCounter++}';

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

  // ═══════════════════════════════════════════════════════════════════════════
  // V5 DETERMINISTIC IDs - Predictable based on inputs
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String labelId({required String name, required LabelType type}) =>
      'label-${name.toLowerCase().replaceAll(' ', '-')}-${type.name}';

  @override
  String trackerId({required String name}) =>
      'tracker-${name.toLowerCase().replaceAll(' ', '-')}';

  @override
  String taskLabelId({required String taskId, required String labelId}) =>
      'task-label-$taskId-$labelId';

  @override
  String projectLabelId({required String projectId, required String labelId}) =>
      'project-label-$projectId-$labelId';

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
  String screenDefinitionId({required String screenKey}) => 'screen-$screenKey';

  @override
  String workflowDefinitionId({required String name}) =>
      'workflow-def-${name.toLowerCase().replaceAll(' ', '-')}';

  @override
  String trackerResponseId({
    required String journalEntryId,
    required String trackerId,
  }) => 'tracker-response-$journalEntryId-$trackerId';

  @override
  String dailyTrackerResponseId({
    required String trackerId,
    required DateTime responseDate,
  }) {
    final dateKey = responseDate.toIso8601String().split('T').first;
    return 'daily-response-$trackerId-$dateKey';
  }

  @override
  String analyticsSnapshotId({
    required String entityType,
    required String entityId,
    required DateTime snapshotDate,
  }) {
    final dateKey = snapshotDate.toIso8601String().split('T').first;
    return 'snapshot-$entityType-$entityId-$dateKey';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Test Utilities
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reset all counters for fresh test state.
  void reset() {
    _taskIdCounter = 0;
    _projectIdCounter = 0;
    _journalEntryIdCounter = 0;
    _workflowRunIdCounter = 0;
    _userProfileIdCounter = 0;
    _pendingNotificationIdCounter = 0;
    _analyticsCorrelationIdCounter = 0;
    _analyticsInsightIdCounter = 0;
  }

  /// Get the next task ID without incrementing the counter.
  /// Useful for assertions.
  String peekNextTaskId() => 'task-$_taskIdCounter';

  /// Get the next project ID without incrementing the counter.
  String peekNextProjectId() => 'project-$_projectIdCounter';
}
