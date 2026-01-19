import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/task_list_row_tile.dart';

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
    final subtitleText = reasonText;
    final subtitle = subtitleText == null || subtitleText.trim().isEmpty
        ? null
        : Text(
            subtitleText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

    return TaskListRowTile(
      model: model,
      onTap: onToggleSelected,
      onToggleCompletion: null,
      titlePrefix: titlePrefix,
      subtitle: subtitle,
      trailing: _SelectPill(selected: selected, onPressed: onToggleSelected),
    );
  }
}

class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final label = selected ? 'Added' : 'Add';

    final background = selected
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHighest;

    final foreground = scheme.onSurfaceVariant;

    final border = selected ? Border.all(color: scheme.outlineVariant) : null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
