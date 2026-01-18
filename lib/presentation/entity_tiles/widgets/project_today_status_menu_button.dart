import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/services.dart';

class ProjectTodayStatusMenuButton extends StatelessWidget {
  const ProjectTodayStatusMenuButton({
    required this.projectId,
    required this.projectName,
    required this.isPinnedToMyDay,
    required this.isInMyDayAuto,
    required this.isRepeating,
    required this.seriesEnded,
    required this.tileCapabilities,
    super.key,
  });

  final String projectId;
  final String projectName;
  final bool isPinnedToMyDay;
  final bool isInMyDayAuto;
  final bool isRepeating;
  final bool seriesEnded;
  final EntityTileCapabilities tileCapabilities;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final statusLabel = switch ((isPinnedToMyDay, isInMyDayAuto)) {
      (true, _) => 'Pinned to My Day',
      (false, true) => 'In My Day',
      _ => null,
    };

    final statusIcon = switch ((isPinnedToMyDay, isInMyDayAuto)) {
      (true, _) => Icons.push_pin,
      (false, true) => Icons.wb_sunny_outlined,
      _ => null,
    };

    final iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.85);

    final statusWidget = (statusIcon == null)
        ? null
        : Tooltip(
            message: statusLabel,
            child: Semantics(
              label: statusLabel,
              child: Icon(statusIcon, size: 20, color: iconColor),
            ),
          );

    final actions = TileOverflowActionCatalog.forProject(
      projectId: projectId,
      projectName: projectName,
      isPinnedToMyDay: isPinnedToMyDay,
      isRepeating: isRepeating,
      seriesEnded: seriesEnded,
      tileCapabilities: tileCapabilities,
    );

    final hasAnyEnabledAction = actions.any((a) => a.enabled);
    if (!hasAnyEnabledAction) {
      return statusWidget ?? const SizedBox.shrink();
    }

    return PopupMenuButton<TileOverflowActionId>(
      tooltip: 'More',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusWidget != null) ...[
              statusWidget,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.more_horiz,
              size: 20,
              color: iconColor,
            ),
          ],
        ),
      ),
      onSelected: (actionId) async {
        final dispatcher = context.read<TileIntentDispatcher>();
        final action = actions.firstWhere((a) => a.id == actionId);

        AppLog.routineThrottledStructured(
          'tile_overflow.project.${actionId.name}.$projectId',
          const Duration(seconds: 2),
          'tile_overflow',
          'selected',
          fields: {
            'entityType': 'project',
            'entityId': projectId,
            'action': actionId.name,
          },
        );

        return dispatcher.dispatch(context, action.intent);
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<TileOverflowActionId>>[];
        TileOverflowActionGroup? lastGroup;

        for (final action in actions) {
          if (lastGroup != null && action.group != lastGroup) {
            if (items.isNotEmpty) items.add(const PopupMenuDivider());
          }
          lastGroup = action.group;

          items.add(
            PopupMenuItem<TileOverflowActionId>(
              value: action.id,
              enabled: action.enabled,
              child: Text(action.label),
            ),
          );
        }

        return items;
      },
    );
  }
}
