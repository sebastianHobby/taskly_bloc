import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';

Future<void> showTileOverflowMenu(
  BuildContext context, {
  required Offset position,
  required String entityTypeLabel,
  required String entityId,
  required List<TileOverflowActionEntry> actions,
}) async {
  if (!context.mounted) return;

  final overlay = Overlay.of(context);
  final overlayObject = overlay.context.findRenderObject();
  if (overlayObject is! RenderBox) return;
  final overlayBox = overlayObject;

  final relativeRect = RelativeRect.fromSize(
    Rect.fromCenter(center: position, width: 1, height: 1),
    overlayBox.size,
  );

  final selected = await showMenu<TileOverflowActionId>(
    context: context,
    position: relativeRect,
    items: _buildOverflowMenuItems(actions),
  );

  if (selected == null) return;
  if (!context.mounted) return;

  final dispatcher = context.read<TileIntentDispatcher>();
  final action = actions.firstWhere((a) => a.id == selected);

  AppLog.routineThrottledStructured(
    'tile_overflow.$entityTypeLabel.${selected.name}.$entityId',
    const Duration(seconds: 2),
    'tile_overflow',
    'selected',
    fields: {
      'entityType': entityTypeLabel,
      'entityId': entityId,
      'action': selected.name,
    },
  );

  await dispatcher.dispatch(context, action.intent);
}

List<PopupMenuEntry<TileOverflowActionId>> _buildOverflowMenuItems(
  List<TileOverflowActionEntry> actions,
) {
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
}
