import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// Canonical Value ("My Values") entity tile.
///
/// This widget is render-only. The app owns all domain semantics and
/// user-facing strings.
class ValueEntityTile extends StatelessWidget {
  const ValueEntityTile({
    required this.model,
    this.preset = const TasklyValueRowPreset.standard(),
    this.actions = const TasklyValueRowActions(),
    super.key,
  });

  final TasklyValueRowData model;

  final TasklyValueRowPreset preset;
  final TasklyValueRowActions actions;

  @override
  Widget build(BuildContext context) {
    return switch (preset) {
      TasklyValueRowPresetBulkSelection(:final selected) => _StandardListRow(
        model: model,
        actions: actions,
        bulkSelected: selected,
      ),
      _ => _StandardListRow(
        model: model,
        actions: actions,
      ),
    };
  }
}

class _StandardListRow extends StatelessWidget {
  const _StandardListRow({
    required this.model,
    required this.actions,
    this.bulkSelected,
  });

  final TasklyValueRowData model;
  final TasklyValueRowActions actions;
  final bool? bulkSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Container(
      key: Key('value-${model.id}'),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: bulkSelected == null
            ? actions.onTap
            : (actions.onToggleSelected ?? actions.onTap),
        onLongPress: actions.onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueIconAvatar(
                icon: model.icon,
                color: model.accentColor,
                size: 44,
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Text(
                  model.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              SizedBox(
                width: 56,
                child: Align(
                  alignment: Alignment.topRight,
                  child: switch (bulkSelected) {
                    null => const SizedBox.shrink(),
                    final selected => _BulkSelectIcon(
                      selected: selected,
                      onPressed: actions.onToggleSelected ?? actions.onTap,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueIconAvatar extends StatelessWidget {
  const _ValueIconAvatar({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.52,
      ),
    );
  }
}

class _BulkSelectIcon extends StatelessWidget {
  const _BulkSelectIcon({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    return IconButton(
      tooltip: selected ? 'Deselect' : 'Select',
      onPressed: onPressed,
      icon: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(tokens.spaceSm2),
      ),
    );
  }
}
