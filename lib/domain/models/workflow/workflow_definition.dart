import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';

part 'workflow_definition.freezed.dart';
part 'workflow_definition.g.dart';

/// Template for a multi-step workflow.
///
/// Workflows are composed of steps, each containing sections (same as screens).
/// Global support blocks can provide workflow-wide context like progress.
@freezed
abstract class WorkflowDefinition with _$WorkflowDefinition {
  const factory WorkflowDefinition({
    required String id,
    required String name,
    required List<WorkflowStep> steps,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Support blocks shown throughout workflow (e.g., progress)
    @Default([]) List<SupportBlock> globalSupportBlocks,

    /// Workflow-level trigger configuration
    TriggerConfig? triggerConfig,

    /// Last time this workflow was completed
    DateTime? lastCompletedAt,

    /// Workflow description
    String? description,

    /// Workflow icon name
    String? iconName,

    /// Whether this is a system-provided workflow
    @Default(false) bool isSystem,

    /// Whether the workflow is active/visible
    @Default(true) bool isActive,
  }) = _WorkflowDefinition;

  const WorkflowDefinition._();

  factory WorkflowDefinition.fromJson(Map<String, dynamic> json) =>
      _$WorkflowDefinitionFromJson(json);

  /// Get step by index
  WorkflowStep? getStep(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  /// Get step by ID
  WorkflowStep? getStepById(String stepId) {
    return steps.where((s) => s.id == stepId).firstOrNull;
  }

  /// Total number of steps
  int get totalSteps => steps.length;
}
