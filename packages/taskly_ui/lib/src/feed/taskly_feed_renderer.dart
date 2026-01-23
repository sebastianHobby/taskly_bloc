import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/sections/empty_state_widget.dart';
import 'package:taskly_ui/src/sections/feed_body.dart';
import 'package:taskly_ui/src/tiles/project_entity_tile.dart';
import 'package:taskly_ui/src/tiles/task_entity_tile.dart';
import 'package:taskly_ui/src/tiles/value_entity_tile.dart';

const double _rowIndent = 10;
const double _entityRowSpacing = 12;
const double _sectionSpacing = 18;

class TasklyFeedRenderer extends StatelessWidget {
  const TasklyFeedRenderer({
    required this.spec,
    this.controller,
    this.padding,
    super.key,
  });

  final TasklyFeedSpec spec;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return switch (spec) {
      TasklyFeedLoading() => FeedBody.loading(
        key: const ValueKey('feed-loading'),
      ),
      TasklyFeedError(
        :final message,
        :final retryLabel,
        :final onRetry,
      ) =>
        FeedBody.error(
          message: message,
          retryLabel: retryLabel,
          onRetry: onRetry,
        ),
      TasklyFeedEmpty(:final empty) => FeedBody.empty(
        child: EmptyStateWidget(
          icon: empty.icon,
          title: empty.title,
          description: empty.description,
          actionLabel: empty.actionLabel,
          onAction: empty.onAction,
        ),
      ),
      TasklyFeedContent(:final sections) => FeedBody.child(
        child: ListView.builder(
          controller: controller,
          padding: padding,
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            final content = TasklyFeedRenderer.buildSection(section);
            if (index == sections.length - 1) return content;
            return Padding(
              padding: const EdgeInsets.only(bottom: _sectionSpacing),
              child: content,
            );
          },
        ),
      ),
    };
  }

  static Widget buildSection(TasklySectionSpec section) {
    return switch (section) {
      TasklyStandardListSectionSpec(:final rows) =>
        _RowList(rows: rows, emptyLabel: null, onAddRequested: null),
      TasklyScheduledDaySectionSpec(
        :final title,
        :final isToday,
        :final countLabel,
        :final rows,
        :final emptyLabel,
        :final onAddRequested,
      ) =>
        _ScheduledDaySection(
          title: title,
          isToday: isToday,
          countLabel: countLabel,
          rows: rows,
          emptyLabel: emptyLabel,
          onAddRequested: onAddRequested,
        ),
      TasklyScheduledOverdueSectionSpec(
        :final title,
        :final countLabel,
        :final isCollapsed,
        :final onToggleCollapsed,
        :final rows,
        :final actionLabel,
        :final actionTooltip,
        :final onActionPressed,
      ) =>
        _ScheduledOverdueSection(
          title: title,
          countLabel: countLabel,
          isCollapsed: isCollapsed,
          onToggleCollapsed: onToggleCollapsed,
          rows: rows,
          actionLabel: actionLabel,
          actionTooltip: actionTooltip,
          onActionPressed: onActionPressed,
        ),
    };
  }

  static Widget buildRow(TasklyRowSpec row) {
    final child = switch (row) {
      TasklyHeaderRowSpec() => _HeaderRow(row: row),
      TasklyDividerRowSpec() => _DividerRow(),
      TasklyInlineActionRowSpec() => _InlineActionRow(row: row),
      TasklyTaskRowSpec() => _TaskRow(row: row),
      TasklyProjectRowSpec() => _ProjectRow(row: row),
      TasklyValueRowSpec() => _ValueRow(row: row),
    };

    final key = switch (row) {
      TasklyHeaderRowSpec(:final key) => key,
      TasklyDividerRowSpec(:final key) => key,
      TasklyInlineActionRowSpec(:final key) => key,
      TasklyTaskRowSpec(:final key) => key,
      TasklyProjectRowSpec(:final key) => key,
      TasklyValueRowSpec(:final key) => key,
    };

    final depth = switch (row) {
      TasklyHeaderRowSpec(:final depth) => depth,
      TasklyDividerRowSpec(:final depth) => depth,
      TasklyInlineActionRowSpec(:final depth) => depth,
      TasklyTaskRowSpec(:final depth) => depth,
      TasklyProjectRowSpec(:final depth) => depth,
      TasklyValueRowSpec() => 0,
    };

    final indented = depth <= 0
        ? child
        : Padding(
            padding: EdgeInsets.only(left: depth * _rowIndent),
            child: child,
          );

    return KeyedSubtree(key: ValueKey(key), child: indented);
  }
}

class _RowList extends StatelessWidget {
  const _RowList({
    required this.rows,
    required this.emptyLabel,
    required this.onAddRequested,
  });

  final List<TasklyRowSpec> rows;
  final String? emptyLabel;
  final VoidCallback? onAddRequested;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && emptyLabel != null) {
      return _EmptyRow(
        label: emptyLabel!,
        onAddRequested: onAddRequested,
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < rows.length; i += 1) {
      final row = rows[i];
      children.add(TasklyFeedRenderer.buildRow(row));

      final isLast = i == rows.length - 1;
      if (isLast) continue;

      final spacing = _spacingAfter(row);
      if (spacing > 0) {
        children.add(SizedBox(height: spacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

double _spacingAfter(TasklyRowSpec row) {
  return switch (row) {
    TasklyHeaderRowSpec() => 0,
    TasklyDividerRowSpec() => 0,
    TasklyInlineActionRowSpec() => _entityRowSpacing,
    TasklyTaskRowSpec() => _entityRowSpacing,
    TasklyProjectRowSpec() => _entityRowSpacing,
    TasklyValueRowSpec() => _entityRowSpacing,
  };
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.row});

  final TasklyHeaderRowSpec row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final text = Text(
      row.title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (row.leadingIcon != null) ...[
              Icon(
                row.leadingIcon,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: text),
            if (row.trailingLabel != null) ...[
              Text(
                row.trailingLabel!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (row.trailingIcon != null)
              Icon(row.trailingIcon, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: row.onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: row.onTap,
              child: content,
            ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: scheme.outlineVariant.withValues(alpha: 0.55),
    );
  }
}

class _InlineActionRow extends StatelessWidget {
  const _InlineActionRow({required this.row});

  final TasklyInlineActionRowSpec row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: row.onTap,
          child: Text(row.label),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.row});

  final TasklyTaskRowSpec row;

  @override
  Widget build(BuildContext context) {
    final emphasis = row.emphasis;
    final leadingAccentColor = emphasis == TasklyRowEmphasis.overdue
        ? Theme.of(context).colorScheme.error
        : null;

    return TaskEntityTile(
      model: row.data,
      intent: row.intent,
      markers: row.markers,
      actions: row.actions,
      leadingAccentColor: leadingAccentColor,
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.row});

  final TasklyProjectRowSpec row;

  @override
  Widget build(BuildContext context) {
    return switch (row.intent) {
      TasklyProjectRowIntentGroupHeader(:final expanded) =>
        _ProjectGroupHeaderRow(
          data: row.data,
          actions: row.actions,
          expanded: expanded,
        ),
      _ => ProjectEntityTile(
        model: row.data,
        intent: row.intent,
        actions: row.actions,
        leadingAccentColor: row.emphasis == TasklyRowEmphasis.overdue
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    };
  }
}

class _ProjectGroupHeaderRow extends StatelessWidget {
  const _ProjectGroupHeaderRow({
    required this.data,
    required this.actions,
    required this.expanded,
  });

  final TasklyProjectRowData data;
  final TasklyProjectRowActions actions;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final onTap = actions.onToggleExpanded ?? actions.onTap;

    final trailingLabel = data.groupTrailingLabel?.trim();
    final hasTrailingLabel =
        trailingLabel != null && trailingLabel.isNotEmpty;

    final icon = data.groupLeadingIcon ?? Icons.folder_outlined;

    final canExpand = actions.onToggleExpanded != null;
    final trailingIcon = canExpand
        ? (expanded ? Icons.expand_less : Icons.expand_more)
        : Icons.chevron_right;

    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (hasTrailingLabel) ...[
              Text(
                trailingLabel ?? '',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              trailingIcon,
              size: 18,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: row,
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.row});

  final TasklyValueRowSpec row;

  @override
  Widget build(BuildContext context) {
    return ValueEntityTile(
      model: row.data,
      intent: row.intent,
      actions: row.actions,
    );
  }
}

class _ScheduledDaySection extends StatelessWidget {
  const _ScheduledDaySection({
    required this.title,
    required this.isToday,
    required this.countLabel,
    required this.rows,
    required this.emptyLabel,
    required this.onAddRequested,
  });

  final String title;
  final bool isToday;
  final String? countLabel;
  final List<TasklyRowSpec> rows;
  final String? emptyLabel;
  final VoidCallback? onAddRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveCount = countLabel?.trim();
    final hasCount = effectiveCount != null && effectiveCount.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 10),
                        _TodayPill(),
                      ],
                    ],
                  ),
                ),
                if (hasCount)
                  Text(
                    effectiveCount,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 12),
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          _RowList(
            rows: rows,
            emptyLabel: emptyLabel ?? 'No tasks',
            onAddRequested: onAddRequested,
          ),
        ],
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'TODAY',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: scheme.onPrimaryContainer,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label, required this.onAddRequested});

  final String label;
  final VoidCallback? onAddRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onAddRequested != null)
              TextButton.icon(
                onPressed: onAddRequested,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledOverdueSection extends StatelessWidget {
  const _ScheduledOverdueSection({
    required this.title,
    required this.countLabel,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    required this.rows,
    required this.actionLabel,
    required this.actionTooltip,
    required this.onActionPressed,
  });

  final String title;
  final String countLabel;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;
  final List<TasklyRowSpec> rows;
  final String? actionLabel;
  final String? actionTooltip;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final trimmedLabel = actionLabel?.trim();
    final hasAction =
        trimmedLabel != null &&
        trimmedLabel.isNotEmpty &&
        onActionPressed != null;

    final visibleRows = isCollapsed ? rows.take(3).toList() : rows;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggleCollapsed,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (hasAction)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: actionTooltip ?? trimmedLabel,
                          child: TextButton.icon(
                            onPressed: onActionPressed,
                            icon: const Icon(Icons.event, size: 18),
                            label: Text(trimmedLabel),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        countLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isCollapsed
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
            if (!isCollapsed || rows.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: visibleRows.isEmpty
                    ? Text(
                        'Nothing overdue',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : _RowList(
                        rows: visibleRows,
                        emptyLabel: null,
                        onAddRequested: null,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
