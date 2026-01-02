import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';

part 'workflow_step.freezed.dart';
part 'workflow_step.g.dart';

/// A single step in a workflow definition
@freezed
abstract class WorkflowStep with _$WorkflowStep {
  const factory WorkflowStep({
    required String stepName,
    required ViewDefinition view,
  }) = _WorkflowStep;

  factory WorkflowStep.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepFromJson(json);
}
