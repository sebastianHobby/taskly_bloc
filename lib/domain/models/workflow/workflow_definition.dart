import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';

part 'workflow_definition.freezed.dart';
part 'workflow_definition.g.dart';

/// Template for a multi-step workflow
@freezed
abstract class WorkflowDefinition with _$WorkflowDefinition {
  const factory WorkflowDefinition({
    required String id,
    required String name,
    required List<WorkflowStep> steps,
    required DateTime createdAt,
    required DateTime updatedAt,
    TriggerConfig? triggerConfig,
    DateTime? lastCompletedAt,
    String? description,
    String? iconName,
    @Default(false) bool isSystem,
    @Default(true) bool isActive,
  }) = _WorkflowDefinition;

  factory WorkflowDefinition.fromJson(Map<String, dynamic> json) =>
      _$WorkflowDefinitionFromJson(json);
}
