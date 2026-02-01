import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

/// Resolves baseline tile capabilities from an entity model.
///
/// Module-level overrides should be applied in the domain layer, but this
/// helper keeps the baseline rules centralized.
class EntityTileCapabilitiesResolver {
  const EntityTileCapabilitiesResolver._();

  static EntityTileCapabilities forEntity({
    required EntityType entityType,
    Task? task,
    Project? project,
    Value? value,
    EntityTileCapabilitiesOverride? override,
  }) {
    final base = switch (entityType) {
      EntityType.task => _forTask(task!),
      EntityType.project => _forProject(project!),
      EntityType.value => _forValue(value!),
    };

    return base.applyOverride(override);
  }

  static EntityTileCapabilities forTask(
    Task task, {
    EntityTileCapabilitiesOverride? override,
  }) => _forTask(task).applyOverride(override);

  static EntityTileCapabilities forProject(
    Project project, {
    EntityTileCapabilitiesOverride? override,
  }) => _forProject(project).applyOverride(override);

  static EntityTileCapabilities forValue(
    Value value, {
    EntityTileCapabilitiesOverride? override,
  }) => _forValue(value).applyOverride(override);

  static EntityTileCapabilities _forTask(Task task) {
    final hasOccurrence = task.occurrence != null;

    return EntityTileCapabilities(
      canToggleCompletion: true,
      completionScope: hasOccurrence
          ? CompletionScope.occurrence
          : CompletionScope.entity,
      canDelete: true,
      canOpenEditor: true,
      canOpenMoveToProject: true,
      canQuickMoveToProject: true,
    );
  }

  static EntityTileCapabilities _forProject(Project project) {
    final hasOccurrence = project.occurrence != null;

    return EntityTileCapabilities(
      canToggleCompletion: true,
      completionScope: hasOccurrence
          ? CompletionScope.occurrence
          : CompletionScope.entity,
      canDelete: true,
      canOpenEditor: true,
      canOpenDetails: true,
    );
  }

  static EntityTileCapabilities _forValue(Value value) {
    return const EntityTileCapabilities(
      canDelete: true,
      canOpenEditor: true,
      canOpenDetails: true,
    );
  }
}
