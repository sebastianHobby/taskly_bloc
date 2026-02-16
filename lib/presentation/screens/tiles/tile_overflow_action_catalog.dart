import 'package:taskly_bloc/l10n/l10n.dart';
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
  toggleCompletion,
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
    required AppLocalizations l10n,
    required EntityType entityType,
    required String entityId,
    required String entityName,
    required bool completed,
    required bool isRepeating,
    required bool seriesEnded,
    bool canToggleCompletion = true,
  }) {
    final canCompleteSeries = isRepeating && !seriesEnded;
    return [
      TileOverflowActionEntry(
        id: TileOverflowActionId.toggleCompletion,
        group: TileOverflowActionGroup.edit,
        label: completed ? l10n.markIncompleteAction : l10n.markCompleteAction,
        enabled: canToggleCompletion,
        destructive: false,
        intent: TileIntentSetCompletion(
          entityType: entityType,
          entityId: entityId,
          entityName: entityName,
          completed: !completed,
          scope: CompletionScope.entity,
        ),
      ),
      TileOverflowActionEntry(
        id: TileOverflowActionId.completeSeries,
        group: TileOverflowActionGroup.destructive,
        label: l10n.completeSeriesAction,
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
        label: l10n.deleteLabel,
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
    required AppLocalizations l10n,
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
        label: l10n.editLabel,
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
        label: l10n.moveToProjectAction,
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
        label: l10n.completeSeriesAction,
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
        label: l10n.deleteLabel,
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
    required AppLocalizations l10n,
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
        label: l10n.editLabel,
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
        label: l10n.completeSeriesAction,
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
        label: l10n.deleteLabel,
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
