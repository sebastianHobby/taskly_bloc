import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';

/// Presentation model for workflow execution.
///
/// Extracts the essential fields from a [ScreenDefinition] needed
/// to run a workflow, simplifying the BLoC interface.
class WorkflowScreen {
  const WorkflowScreen({
    required this.id,
    required this.screenKey,
    required this.name,
    required this.selector,
    required this.display,
  });

  /// Creates a [WorkflowScreen] from a [ScreenDefinition].
  ///
  /// Throws [ArgumentError] if the view definition doesn't support
  /// workflow execution (must be collection, agenda, or allocated).
  factory WorkflowScreen.fromScreenDefinition(ScreenDefinition definition) {
    final view = definition.view;

    return switch (view) {
      CollectionView(:final selector, :final display) => WorkflowScreen(
        id: definition.id,
        screenKey: definition.screenKey,
        name: definition.name,
        selector: selector,
        display: display,
      ),
      AgendaView(:final selector, :final display) => WorkflowScreen(
        id: definition.id,
        screenKey: definition.screenKey,
        name: definition.name,
        selector: selector,
        display: display,
      ),
      AllocatedView(:final selector, :final display) => WorkflowScreen(
        id: definition.id,
        screenKey: definition.screenKey,
        name: definition.name,
        selector: selector,
        display: display,
      ),
      DetailView() => throw ArgumentError(
        'DetailView does not support workflow execution',
      ),
    };
  }

  /// Unique identifier for this screen definition.
  final String id;

  /// Screen key for persistence and routing.
  final String screenKey;

  /// Display name for the workflow.
  final String name;

  /// Selector determining which entities to include.
  final EntitySelector selector;

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
          selector == other.selector &&
          display == other.display;

  @override
  int get hashCode => Object.hash(id, screenKey, name, selector, display);
}
