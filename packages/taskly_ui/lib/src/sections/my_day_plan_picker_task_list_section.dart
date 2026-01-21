import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/task_entity_tile.dart';

@immutable
final class MyDayPlanPickerTaskItem {
  const MyDayPlanPickerTaskItem({
    required this.model,
    required this.selected,
    this.markers = const TaskTileMarkers(),
    this.supportingText,
    this.supportingTooltipText,
    this.onToggleSelected,
    this.onSnoozeRequested,
  });

  final TaskTileModel model;
  final bool selected;
  final TaskTileMarkers markers;

  final String? supportingText;
  final String? supportingTooltipText;

  /// When null, the row is not selectable.
  final VoidCallback? onToggleSelected;

  /// Optional secondary action shown next to the Add/Added pill.
  final VoidCallback? onSnoozeRequested;
}

/// Renders a list of task rows in the My Day ritual "plan picker" style.
///
/// This is pure UI: callers provide tile models and callbacks.
class MyDayPlanPickerTaskListSection extends StatelessWidget {
  const MyDayPlanPickerTaskListSection({
    required this.items,
    super.key,
  });

  final List<MyDayPlanPickerTaskItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          TaskEntityTile(
            model: item.model,
            intent: TaskTileIntent.ritualPick(selected: item.selected),
            supportingText: item.supportingText,
            supportingTooltipText: item.supportingTooltipText,
            markers: item.markers,
            actions: TaskTileActions(
              onTap: item.onToggleSelected,
              onToggleSelected: item.onToggleSelected,
              onSnoozeRequested: item.onSnoozeRequested,
            ),
          ),
      ],
    );
  }
}
