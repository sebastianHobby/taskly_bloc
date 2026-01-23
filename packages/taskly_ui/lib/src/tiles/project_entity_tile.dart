import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/tiles/entity_tile_theme.dart';

/// Canonical Project tile aligned to Stitch mockups.
///
/// Pure UI: data in / events out.
class ProjectEntityTile extends StatelessWidget {
  const ProjectEntityTile({
    required this.model,
    this.intent = const TasklyProjectRowIntent.standard(),
    this.actions = const TasklyProjectRowActions(),
    this.leadingAccentColor,
    super.key,
  });

  final TasklyProjectRowData model;

  final TasklyProjectRowIntent intent;
  final TasklyProjectRowActions actions;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  bool? get _selected => switch (intent) {
    TasklyProjectRowIntentBulkSelection(:final selected) => selected,
    _ => null,
  };

  double? get _progress {
    final total = model.taskCount;
    final done = model.completedTaskCount;
    if (total == null || done == null || total <= 0) return null;
    return (done / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final effectiveCompact = MediaQuery.sizeOf(context).width < 420;
    final padding = effectiveCompact
        ? const EdgeInsets.all(16)
        : tokens.projectPadding;

    final borderColor = scheme.outlineVariant.withValues(alpha: 0.55);
    final surfaceColor = scheme.surface;

    final pinnedPrefix = model.pinned ? const _PinnedGlyph() : null;

    final Widget? titlePrefix = pinnedPrefix;

    final baseOpacity = model.deemphasized ? 0.6 : 1.0;
    final completedOpacity = model.completed ? 0.75 : 1.0;
    final opacity = (baseOpacity * completedOpacity).clamp(0.0, 1.0);

    final onTap = switch (intent) {
      TasklyProjectRowIntentBulkSelection() =>
        actions.onToggleSelected ?? actions.onTap,
      _ => actions.onTap,
    };

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(tokens.projectRadius),
        border: Border.all(color: borderColor),
        boxShadow: [tokens.shadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.projectRadius),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: actions.onLongPress,
            child: Stack(
              children: [
                if (leadingAccentColor != null)
                  Positioned.fill(
                    left: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(width: 4, color: leadingAccentColor),
                    ),
                  ),
                Padding(
                  padding: padding.copyWith(
                    left: (leadingAccentColor == null)
                        ? padding.left
                        : (padding.left + 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopRow(
                        leadingChip: model.leadingChip,
                        priority: model.meta.priority,
                        selected: _selected,
                        onToggleSelected: actions.onToggleSelected,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (titlePrefix != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: titlePrefix,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              model.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tokens.projectTitle.copyWith(
                                color: scheme.onSurface,
                                decoration: model.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: scheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (model.subtitle != null &&
                          model.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          model.subtitle!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.subtitle.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (_progress != null) ...[
                        const SizedBox(height: 12),
                        _ProgressRow(
                          progress: _progress!,
                          tokens: tokens,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _PlanDueRow(meta: model.meta, tokens: tokens),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Opacity(
      key: Key('project-${model.id}'),
      opacity: opacity,
      child: card,
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.leadingChip,
    required this.priority,
    required this.selected,
    required this.onToggleSelected,
  });

  final ValueChipData? leadingChip;
  final int? priority;
  final bool? selected;
  final VoidCallback? onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final chip = leadingChip;

    final badge = _PriorityBadge(priority: priority, tokens: tokens);

    Widget? selectionWidget;
    if (selected != null) {
      selectionWidget = IconButton(
        tooltip: (selected ?? false) ? 'Deselect' : 'Select',
        onPressed: onToggleSelected,
        icon: Icon(
          (selected ?? false)
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: (selected ?? false) ? scheme.primary : scheme.onSurfaceVariant,
        ),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
        ),
      );
    }

    return Row(
      children: [
        if (chip != null) _ValueChip(data: chip, textStyle: tokens.chipText),
        const Spacer(),
        badge,
        ...?(selectionWidget == null ? null : [selectionWidget]),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress, required this.tokens});

  final double progress;
  final TasklyEntityTileTheme tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PROGRESS',
              style: tokens.metaLabelCaps.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: tokens.metaValue.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanDueRow extends StatelessWidget {
  const _PlanDueRow({required this.meta, required this.tokens});

  final TasklyEntityMetaData meta;
  final TasklyEntityTileTheme tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final plan = meta.startDateLabel?.trim();
    final due = meta.deadlineDateLabel?.trim();

    final hasPlan =
        plan != null && plan.isNotEmpty && !meta.showOnlyDeadlineDate;
    final hasDue = due != null && due.isNotEmpty;

    if (!hasPlan && !hasDue) return const SizedBox.shrink();

    final labelStyle = tokens.metaLabelCaps.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
    );

    final dueColor = meta.isOverdue || meta.isDueToday
        ? scheme.error
        : scheme.onSurfaceVariant;

    final dueLabelStyle = tokens.metaLabelCaps.copyWith(
      color: dueColor.withValues(alpha: 0.9),
    );

    final valueStyle = tokens.metaValue.copyWith(color: scheme.onSurface);
    final dueValueStyle = tokens.metaValue.copyWith(color: dueColor);

    Widget item({
      required IconData icon,
      required TextStyle labelStyle,
      required String label,
      required TextStyle valueStyle,
      required String value,
      required Color iconColor,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(label, style: labelStyle),
            const SizedBox(width: 8),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (hasPlan)
          item(
            icon: Icons.calendar_today_rounded,
            labelStyle: labelStyle,
            label: 'PLAN',
            valueStyle: valueStyle,
            value: plan,
            iconColor: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        if (hasDue)
          item(
            icon: Icons.flag_rounded,
            labelStyle: dueLabelStyle,
            label: 'DUE',
            valueStyle: dueValueStyle,
            value: due,
            iconColor: dueColor,
          ),
      ],
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.data, required this.textStyle});

  final ValueChipData data;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final fg = data.color;
    final bg = data.color.withValues(alpha: isDark ? 0.22 : 0.14);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: fg),
          const SizedBox(width: 8),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority, required this.tokens});

  final int? priority;
  final TasklyEntityTileTheme tokens;

  @override
  Widget build(BuildContext context) {
    final p = priority;
    if (p == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final String label = 'P$p';

    final Color bg;
    final Color fg;
    final BorderSide? border;

    if (p == 1) {
      bg = scheme.error;
      fg = scheme.onError;
      border = null;
    } else if (p == 2) {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
      border = null;
    } else {
      bg = Colors.transparent;
      fg = scheme.onSurfaceVariant;
      border = BorderSide(color: scheme.outlineVariant);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border == null ? null : Border.fromBorderSide(border),
      ),
      child: Text(
        label,
        style: tokens.priorityBadge.copyWith(color: fg),
      ),
    );
  }
}

class _PinnedGlyph extends StatelessWidget {
  const _PinnedGlyph();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Pinned',
      child: SizedBox(
        width: 18,
        child: Align(
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
