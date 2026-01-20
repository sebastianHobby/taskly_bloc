import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/task_entity_tile.dart';

/// A task row tile variant for selection flows.
///
/// This is intended for experiences like “pick tasks for today” where:
/// - tapping the row toggles selection (instead of opening an editor)
/// - completion toggles are disabled
/// - an optional reason subtitle can be shown
/// - a trailing Add/Added pill communicates selection
class SelectableTaskEntityTile extends StatelessWidget {
  const SelectableTaskEntityTile({
    required this.model,
    required this.selected,
    required this.onToggleSelected,
    this.onSnoozeRequested,
    this.reasonText,
    this.titlePrefix,
    super.key,
  });

  final TaskTileModel model;

  final bool selected;

  /// Called when the user toggles selection.
  ///
  /// This is invoked from both row tap and the trailing pill.
  final VoidCallback onToggleSelected;

  /// Optional secondary action shown next to the selection pill.
  final VoidCallback? onSnoozeRequested;

  /// Optional subtitle shown between title and meta line.
  ///
  /// Commonly used to show “why this was suggested”.
  final String? reasonText;

  /// Optional widget displayed before the title.
  ///
  /// This is intentionally a narrow extension point to avoid re-exposing the
  /// full TaskListRowTile API.
  final Widget? titlePrefix;

  @override
  Widget build(BuildContext context) {
    return TaskEntityTile(
      model: model,
      intent: TaskTileIntent.selection(selected: selected),
      actions: TaskTileActions(
        onTap: onToggleSelected,
        onToggleSelected: onToggleSelected,
        onSnoozeRequested: onSnoozeRequested,
      ),
      markers: const TaskTileMarkers(),
      supportingText: reasonText,
    );
  }
}
