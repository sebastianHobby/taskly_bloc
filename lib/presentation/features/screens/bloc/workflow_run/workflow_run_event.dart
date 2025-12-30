part of 'workflow_run_bloc.dart';

@freezed
sealed class WorkflowRunEvent with _$WorkflowRunEvent {
  /// Start the workflow by loading items
  const factory WorkflowRunEvent.started() = _Started;

  /// Mark current item as reviewed
  const factory WorkflowRunEvent.itemMarkedReviewed({
    required String entityId,
    String? notes,
  }) = _ItemMarkedReviewed;

  /// Skip current item
  const factory WorkflowRunEvent.itemSkipped({
    required String entityId,
    String? reason,
  }) = _ItemSkipped;

  /// Move to next item
  const factory WorkflowRunEvent.nextItemRequested() = _NextItemRequested;

  /// Move to previous item
  const factory WorkflowRunEvent.previousItemRequested() =
      _PreviousItemRequested;

  /// Jump to specific item by index
  const factory WorkflowRunEvent.itemJumpedTo({
    required int index,
  }) = _ItemJumpedTo;

  /// Complete the workflow
  const factory WorkflowRunEvent.workflowCompleted() = _WorkflowCompleted;

  /// Acknowledge a detected soft gate problem.
  const factory WorkflowRunEvent.problemAcknowledged({
    required ProblemType problemType,
    required EntityType entityType,
    required String entityId,
  }) = _ProblemAcknowledged;

  /// Snooze a detected soft gate problem.
  const factory WorkflowRunEvent.problemSnoozed({
    required ProblemType problemType,
    required EntityType entityType,
    required String entityId,
  }) = _ProblemSnoozed;

  /// Dismiss a detected soft gate problem.
  const factory WorkflowRunEvent.problemDismissed({
    required ProblemType problemType,
    required EntityType entityType,
    required String entityId,
  }) = _ProblemDismissed;
}
