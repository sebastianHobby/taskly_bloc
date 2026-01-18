import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/core.dart';

class TaskTodayStatusMenuButton extends StatelessWidget {
  const TaskTodayStatusMenuButton({
    required this.taskId,
    required this.taskName,
    required this.isPinnedToMyDay,
    required this.isInMyDayAuto,
    required this.isRepeating,
    required this.seriesEnded,
    required this.tileCapabilities,
    super.key,
    this.compact = false,
  });

  final String taskId;
  final String taskName;
  final bool isPinnedToMyDay;
  final bool isInMyDayAuto;
  final bool isRepeating;
  final bool seriesEnded;
  final EntityTileCapabilities tileCapabilities;
  final bool compact;

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
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Tooltip(
              message: statusLabel,
              child: Semantics(
                label: statusLabel,
                child: Icon(
                  statusIcon,
                  size: compact ? 18 : 20,
                  color: iconColor,
                ),
              ),
            ),
          );

    final actions = TileOverflowActionCatalog.forTask(
      taskId: taskId,
      taskName: taskName,
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
              size: compact ? 18 : 20,
              color: iconColor,
            ),
          ],
        ),
      ),
      onSelected: (actionId) async {
        final dispatcher = context.read<TileIntentDispatcher>();
        final action = actions.firstWhere((a) => a.id == actionId);

        AppLog.routineThrottledStructured(
          'tile_overflow.task.${actionId.name}.$taskId',
          const Duration(seconds: 2),
          'tile_overflow',
          'selected',
          fields: {
            'entityType': 'task',
            'entityId': taskId,
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
