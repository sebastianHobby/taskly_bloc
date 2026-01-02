import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step_state.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

/// Workflow status
enum WorkflowStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('abandoned')
  abandoned,
}

/// Runtime instance of a workflow
@freezed
abstract class Workflow with _$Workflow {
  const factory Workflow({
    required String id,
    required String workflowDefinitionId,
    required WorkflowStatus status,
    required List<WorkflowStepState> stepStates,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    @Default(0) int currentStepIndex,
  }) = _Workflow;

  factory Workflow.fromJson(Map<String, dynamic> json) =>
      _$WorkflowFromJson(json);
}
