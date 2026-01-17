import 'package:taskly_bloc/domain/entity_views/tile_capabilities/entity_tile_capabilities.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_domain/analytics.dart';

enum TileOverflowActionGroup {
  pin,
  edit,
  destructive,
}

enum TileOverflowActionId {
  togglePinnedToMyDay,
  edit,
  moveToProject,
  alignValues,
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
  }) {
    return [
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
    required bool isPinnedToMyDay,
    required EntityTileCapabilities tileCapabilities,
  }) {
    return [
      TileOverflowActionEntry(
        id: TileOverflowActionId.togglePinnedToMyDay,
        group: TileOverflowActionGroup.pin,
        label: isPinnedToMyDay ? 'Unpin from My Day' : 'Pin to My Day',
        enabled: tileCapabilities.canTogglePinned,
        destructive: false,
        intent: TileIntentSetPinned(
          entityType: EntityType.task,
          entityId: taskId,
          isPinned: !isPinnedToMyDay,
        ),
      ),
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
        id: TileOverflowActionId.alignValues,
        group: TileOverflowActionGroup.edit,
        label: 'Align values…',
        enabled: tileCapabilities.canAlignValues,
        destructive: false,
        intent: TileIntentOpenEditor(
          entityType: EntityType.task,
          entityId: taskId,
          openToValues: true,
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
    required bool isPinnedToMyDay,
    required EntityTileCapabilities tileCapabilities,
  }) {
    return [
      TileOverflowActionEntry(
        id: TileOverflowActionId.togglePinnedToMyDay,
        group: TileOverflowActionGroup.pin,
        label: isPinnedToMyDay ? 'Unpin from My Day' : 'Pin to My Day',
        enabled: tileCapabilities.canTogglePinned,
        destructive: false,
        intent: TileIntentSetPinned(
          entityType: EntityType.project,
          entityId: projectId,
          isPinned: !isPinnedToMyDay,
        ),
      ),
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
        id: TileOverflowActionId.alignValues,
        group: TileOverflowActionGroup.edit,
        label: 'Align values…',
        enabled: tileCapabilities.canAlignValues,
        destructive: false,
        intent: TileIntentOpenEditor(
          entityType: EntityType.project,
          entityId: projectId,
          openToValues: true,
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
