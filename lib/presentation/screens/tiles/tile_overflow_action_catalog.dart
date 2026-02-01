import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';

enum TileOverflowActionGroup {
  edit,
  destructive,
}

enum TileOverflowActionId {
  edit,
  moveToProject,
  completeSeries,
  delete,
}

class TileOverflowActionEntry {
  const TileOverflowActionEntry({
    required this.id,
    required this.group,
    required this.label,
    required this.intent,
    required this.enabled,
    required this.destructive,
  });

  final TileOverflowActionId id;
  final TileOverflowActionGroup group;
  final String label;
  final TileIntent intent;
  final bool enabled;
  final bool destructive;
}

/// Central catalog for tile overflow actions.
///
/// This converts entity state + [EntityTileCapabilities] into a stable action
/// list (including disabled items) and corresponding [TileIntent]s.
abstract final class TileOverflowActionCatalog {
  static List<TileOverflowActionEntry> forEntityDetail({
    required EntityType entityType,
    required String entityId,
    required String entityName,
    required bool isRepeating,
    required bool seriesEnded,
  }) {
    final canCompleteSeries = isRepeating && !seriesEnded;
    return [
      TileOverflowActionEntry(
        id: TileOverflowActionId.completeSeries,
        group: TileOverflowActionGroup.destructive,
        label: 'Complete series',
        enabled: canCompleteSeries,
        destructive: true,
        intent: TileIntentCompleteSeries(
          entityType: entityType,
          entityId: entityId,
          entityName: entityName,
        ),
      ),
      TileOverflowActionEntry(
        id: TileOverflowActionId.delete,
        group: TileOverflowActionGroup.destructive,
        label: 'Delete',
        enabled: true,
        destructive: true,
        intent: TileIntentRequestDelete(
          entityType: entityType,
          entityId: entityId,
          entityName: entityName,
          popOnSuccess: true,
        ),
      ),
    ];
  }

  static List<TileOverflowActionEntry> forTask({
    required String taskId,
    required String taskName,
    required bool isRepeating,
    required bool seriesEnded,
    required EntityTileCapabilities tileCapabilities,
  }) {
    final canCompleteSeries =
        tileCapabilities.canToggleCompletion && isRepeating && !seriesEnded;
    return [
      TileOverflowActionEntry(
        id: TileOverflowActionId.edit,
        group: TileOverflowActionGroup.edit,
        label: 'Edit',
        enabled: tileCapabilities.canOpenEditor,
        destructive: false,
        intent: TileIntentOpenEditor(
          entityType: EntityType.task,
          entityId: taskId,
        ),
      ),
      TileOverflowActionEntry(
        id: TileOverflowActionId.moveToProject,
        group: TileOverflowActionGroup.edit,
        label: 'Move to project…',
        enabled: tileCapabilities.canOpenMoveToProject,
        destructive: false,
        intent: TileIntentOpenMoveToProject(
          taskId: taskId,
          taskName: taskName,
          allowOpenEditor: tileCapabilities.canOpenEditor,
          allowQuickMove: tileCapabilities.canQuickMoveToProject,
        ),
      ),
      TileOverflowActionEntry(
        id: TileOverflowActionId.completeSeries,
        group: TileOverflowActionGroup.destructive,
        label: 'Complete series',
        enabled: canCompleteSeries,
        destructive: true,
        intent: TileIntentCompleteSeries(
          entityType: EntityType.task,
          entityId: taskId,
          entityName: taskName,
        ),
      ),
      TileOverflowActionEntry(
        id: TileOverflowActionId.delete,
        group: TileOverflowActionGroup.destructive,
        label: 'Delete',
        enabled: tileCapabilities.canDelete,
        destructive: true,
        intent: TileIntentRequestDelete(
          entityType: EntityType.task,
          entityId: taskId,
          entityName: taskName,
        ),
      ),
    ];
  }

  static List<TileOverflowActionEntry> forProject({
    required String projectId,
    required String projectName,
    required bool isRepeating,
    required bool seriesEnded,
    required EntityTileCapabilities tileCapabilities,
  }) {
    final canCompleteSeries =
        tileCapabilities.canToggleCompletion && isRepeating && !seriesEnded;
    return [
      TileOverflowActionEntry(
        id: TileOverflowActionId.edit,
        group: TileOverflowActionGroup.edit,
        label: 'Edit',
        enabled: tileCapabilities.canOpenEditor,
        destructive: false,
        intent: TileIntentOpenEditor(
          entityType: EntityType.project,
          entityId: projectId,
        ),
      ),
      TileOverflowActionEntry(
        id: TileOverflowActionId.completeSeries,
        group: TileOverflowActionGroup.destructive,
        label: 'Complete series',
        enabled: canCompleteSeries,
        destructive: true,
        intent: TileIntentCompleteSeries(
          entityType: EntityType.project,
          entityId: projectId,
          entityName: projectName,
        ),
      ),
      TileOverflowActionEntry(
        id: TileOverflowActionId.delete,
        group: TileOverflowActionGroup.destructive,
        label: 'Delete',
        enabled: tileCapabilities.canDelete,
        destructive: true,
        intent: TileIntentRequestDelete(
          entityType: EntityType.project,
          entityId: projectId,
          entityName: projectName,
        ),
      ),
    ];
  }
}
