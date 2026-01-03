import 'package:json_annotation/json_annotation.dart';

/// Operations that can be exposed as a FAB on a screen.
///
/// Used by [ScreenDefinition.fabOperations] to declaratively specify
/// what create actions are available on each screen.
enum FabOperation {
  /// Create a new task
  @JsonValue('create_task')
  createTask,

  /// Create a new project
  @JsonValue('create_project')
  createProject,

  /// Create a new label
  @JsonValue('create_label')
  createLabel,

  /// Create a new value (label with type=value)
  @JsonValue('create_value')
  createValue,
}
