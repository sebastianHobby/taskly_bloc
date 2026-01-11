import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_item.freezed.dart';

/// Status of an item in a workflow
enum WorkflowItemStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('skipped')
  skipped,
}

/// Wrapper for entities in workflow screens with review tracking
@Freezed(genericArgumentFactories: true)
abstract class WorkflowItem<T> with _$WorkflowItem<T> {
  const factory WorkflowItem({
    required T entity,
    required String entityId,
    @Default(WorkflowItemStatus.pending) WorkflowItemStatus status,
    DateTime? lastReviewedAt,
    String? notes,
  }) = _WorkflowItem<T>;
}
