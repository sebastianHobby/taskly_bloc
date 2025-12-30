import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';

part 'workflow_session.freezed.dart';
part 'workflow_session.g.dart';

/// Workflow session status
enum WorkflowStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('abandoned')
  abandoned,
}

/// Tracks individual workflow execution session
@freezed
abstract class WorkflowSession with _$WorkflowSession {
  const factory WorkflowSession({
    required String id,
    required String userId,
    required String screenId,
    required DateTime startedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(WorkflowStatus.inProgress) WorkflowStatus status,
    DateTime? completedAt,
    @Default(0) int totalItems,
    @Default(0) int itemsReviewed,
    @Default(0) int itemsSkipped,
    String? sessionNotes,
  }) = _WorkflowSession;

  factory WorkflowSession.fromJson(Map<String, dynamic> json) =>
      _$WorkflowSessionFromJson(json);
}

/// Workflow action types
enum WorkflowAction {
  @JsonValue('reviewed')
  reviewed,
  @JsonValue('skipped')
  skipped,
}

/// Per-item review action within workflow session
@freezed
abstract class WorkflowItemReview with _$WorkflowItemReview {
  const factory WorkflowItemReview({
    required String id,
    required String sessionId,
    required String userId,
    required String entityId,
    required EntityType entityType,
    required WorkflowAction action,
    required DateTime reviewedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? reviewNotes,
  }) = _WorkflowItemReview;

  factory WorkflowItemReview.fromJson(Map<String, dynamic> json) =>
      _$WorkflowItemReviewFromJson(json);
}

/// Workflow progress tracking
@freezed
abstract class WorkflowProgress with _$WorkflowProgress {
  const factory WorkflowProgress({
    required int totalItems,
    required int completedItems,
    required int remainingItems,
    required double percentageComplete,
    required Duration timeElapsed,
  }) = _WorkflowProgress;

  factory WorkflowProgress.fromJson(Map<String, dynamic> json) =>
      _$WorkflowProgressFromJson(json);
}
