import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_type.dart';

// Note: ProblemType enum moved to problem_type.dart
// Re-export for backward compatibility
export 'package:taskly_bloc/domain/models/workflow/problem_type.dart';

part 'problem_acknowledgment.freezed.dart';
part 'problem_acknowledgment.g.dart';

/// Resolution actions for acknowledged problems
enum ResolutionAction {
  @JsonValue('dismissed')
  dismissed,
  @JsonValue('snoozed')
  snoozed,
  @JsonValue('resolved')
  resolved,
  @JsonValue('accepted')
  accepted,
}

/// Problem acknowledgment record for persistence
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

/// Detected problem with context (runtime model, not persisted)
@freezed
abstract class DetectedProblem with _$DetectedProblem {
  const factory DetectedProblem({
    required ProblemType type,
    required String entityId,
    required EntityType entityType,
    required String title,
    required String description,
    required String suggestedAction,
  }) = _DetectedProblem;

  factory DetectedProblem.fromJson(Map<String, dynamic> json) =>
      _$DetectedProblemFromJson(json);
}
