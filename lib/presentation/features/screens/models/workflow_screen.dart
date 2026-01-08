import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/agenda_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/allocation_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/data_list_section_params.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Presentation model for workflow execution.
///
/// Extracts the essential fields from a [ScreenDefinition] needed
/// to run a workflow, simplifying the BLoC interface.
class WorkflowScreen {
  const WorkflowScreen({
    required this.id,
    required this.screenKey,
    required this.name,
    required this.taskQuery,
    required this.display,
  });

  /// Creates a [WorkflowScreen] from a [ScreenDefinition].
  ///
  /// Throws [ArgumentError] if the screen doesn't have task data
  /// that supports workflow execution.
  factory WorkflowScreen.fromScreenDefinition(ScreenDefinition definition) {
    final taskQuery = _extractTaskQuery(definition.sections);
    if (taskQuery == null) {
      throw ArgumentError(
        'Screen "${definition.name}" does not have task data for workflow',
      );
    }

    final display = _extractDisplayConfig(definition.sections);

    return WorkflowScreen(
      id: definition.id,
      screenKey: definition.screenKey,
      name: definition.name,
      taskQuery: taskQuery,
      display: display ?? const DisplayConfig(),
    );
  }

  /// Extracts the TaskQuery from sections.
  static TaskQuery? _extractTaskQuery(List<SectionRef> sections) {
    for (final ref in sections) {
      if (ref.overrides?.enabled == false) continue;

      switch (ref.templateId) {
        case SectionTemplateId.taskList:
        case SectionTemplateId.projectList:
        case SectionTemplateId.valueList:
          final params = DataListSectionParams.fromJson(ref.params);
          final config = params.config;
          if (config is TaskDataConfig) {
            return config.query;
          }
        case SectionTemplateId.allocation:
          final params = AllocationSectionParams.fromJson(ref.params);
          return params.sourceFilter ?? TaskQuery.incomplete();
        case SectionTemplateId.agenda:
          final params = AgendaSectionParams.fromJson(ref.params);
          return params.additionalFilter ?? TaskQuery.incomplete();
      }
    }
    return null;
  }

  /// Extracts the DisplayConfig from sections.
  static DisplayConfig? _extractDisplayConfig(List<SectionRef> sections) {
    for (final ref in sections) {
      if (ref.overrides?.enabled == false) continue;

      if (ref.templateId != SectionTemplateId.taskList &&
          ref.templateId != SectionTemplateId.projectList &&
          ref.templateId != SectionTemplateId.valueList) {
        continue;
      }

      final params = DataListSectionParams.fromJson(ref.params);
      if (params.display case final display?) {
        return display;
      }
    }

    return null;
  }

  /// Unique identifier for this screen definition.
  final String id;

  /// Screen key for persistence and routing.
  final String screenKey;

  /// Display name for the workflow.
  final String name;

  /// Query determining which tasks to include.
  final TaskQuery taskQuery;

  /// Display configuration including sort, filter, and problem detection.
  final DisplayConfig display;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowScreen &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          screenKey == other.screenKey &&
          name == other.name &&
          taskQuery == other.taskQuery &&
          display == other.display;

  @override
  int get hashCode =>
      id.hashCode ^
      screenKey.hashCode ^
      name.hashCode ^
      taskQuery.hashCode ^
      display.hashCode;

  @override
  String toString() {
    return 'WorkflowScreen(id: $id, screenKey: $screenKey, name: $name)';
  }
}
