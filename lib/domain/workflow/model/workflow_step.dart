import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/trigger_config.dart';

part 'workflow_step.freezed.dart';
part 'workflow_step.g.dart';

/// A step in a workflow.
///
/// Each step defines content via sections (same as screens) and can have
/// triggers for progression.
@freezed
abstract class WorkflowStep with _$WorkflowStep {
  const factory WorkflowStep({
    /// Unique identifier for this step
    required String id,

    /// Display name for this step
    required String name,

    /// Position in workflow sequence
    required int order,

    /// Content sections for this step.
    required List<SectionRef> sections,

    /// Step description
    String? description,

    /// Step icon
    String? icon,

    /// Triggers for step transitions
    @Default([]) List<TriggerConfig> triggers,

    /// Whether step is required before moving to next
    @Default(true) bool isRequired,

    /// Estimated duration in minutes
    int? estimatedMinutes,
  }) = _WorkflowStep;

  const WorkflowStep._();

  factory WorkflowStep.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepFromJson(json);
}
