import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';

part 'problem_acknowledgment.freezed.dart';
part 'problem_acknowledgment.g.dart';

/// Problem types for soft gates
enum ProblemType {
  @JsonValue('excluded_urgent_task')
  excludedUrgentTask,
  @JsonValue('overdue_high_priority')
  overdueHighPriority,
  @JsonValue('no_next_actions')
  noNextActions,
  @JsonValue('unbalanced_allocation')
  unbalancedAllocation,
  @JsonValue('stale_tasks')
  staleTasks,
}

/// Resolution actions for problems
enum ResolutionAction {
  @JsonValue('dismissed')
  dismissed,
  @JsonValue('fixed')
  fixed,
  @JsonValue('snoozed')
  snoozed,
}

/// Soft gate warning and user acknowledgment
@freezed
abstract class ProblemAcknowledgment with _$ProblemAcknowledgment {
  const factory ProblemAcknowledgment({
    required String id,
    required String userId,
    required ProblemType problemType,
    required String entityId,
    required EntityType entityType,
    required DateTime acknowledgedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    ResolutionAction? resolutionAction,
    DateTime? snoozeUntil,
  }) = _ProblemAcknowledgment;

  factory ProblemAcknowledgment.fromJson(Map<String, dynamic> json) =>
      _$ProblemAcknowledgmentFromJson(json);
}

/// Detected problem with context
@freezed
abstract class DetectedProblem with _$DetectedProblem {
  const factory DetectedProblem({
    required ProblemType type,
    required String entityId,
    required EntityType entityType,
    required String title,
    required String description,
    required String suggestedAction,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
  }) = _DetectedProblem;

  factory DetectedProblem.fromJson(Map<String, dynamic> json) =>
      _$DetectedProblemFromJson(json);
}
