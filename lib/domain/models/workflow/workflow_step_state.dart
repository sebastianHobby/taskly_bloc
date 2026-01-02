import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_step_state.freezed.dart';
part 'workflow_step_state.g.dart';

/// Runtime state for a single workflow step
@freezed
abstract class WorkflowStepState with _$WorkflowStepState {
  const factory WorkflowStepState({
    required int stepIndex,
    @Default([]) List<String> reviewedEntityIds,
    @Default([]) List<String> skippedEntityIds,
    @Default([]) List<String> pendingEntityIds,
  }) = _WorkflowStepState;

  factory WorkflowStepState.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepStateFromJson(json);
}
