import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/sections/empty_state_widget.dart';
import 'package:taskly_ui/src/sections/feed_body.dart';
import 'package:taskly_ui/src/sections/value_distribution_section.dart';
import 'package:taskly_ui/src/feed/taskly_feed_theme.dart';
import 'package:taskly_ui/src/tiles/entity_tile_theme.dart';
import 'package:taskly_ui/src/tiles/project_entity_tile.dart';
import 'package:taskly_ui/src/tiles/routine_entity_tile.dart';
import 'package:taskly_ui/src/tiles/task_entity_tile.dart';
import 'package:taskly_ui/src/tiles/value_entity_tile.dart';

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
        child: Builder(
          builder: (context) {
            final feedTheme = TasklyFeedTheme.of(context);
            return ListView.builder(
              controller: controller,
              padding: padding,
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final content = TasklyFeedRenderer.buildSection(section);
                if (index == sections.length - 1) return content;
                return Padding(
                  padding: EdgeInsets.only(bottom: feedTheme.sectionSpacing),
                  child: content,
                );
              },
            );
          },
        ),
      ),
    };
  }

  static Widget buildSection(TasklySectionSpec section) {
    return switch (section) {
      TasklyStandardListSectionSpec(:final rows) => _RowList(
        rows: rows,
        emptyLabel: null,
        onAddRequested: null,
      ),
      TasklyValueDistributionSectionSpec(
        :final title,
        :final totalLabel,
        :final entries,
      ) =>
        ValueDistributionSection(
          title: title,
          totalLabel: totalLabel,
          entries: entries,
        ),
      TasklyScheduledDaySectionSpec(
        :final title,
        :final countLabel,
        :final rows,
        :final emptyLabel,
        :final onAddRequested,
      ) =>
        _ScheduledDaySection(
          title: title,
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

  static Widget buildRow(TasklyRowSpec row, {BuildContext? context}) {
    final feedTheme = context == null ? null : TasklyFeedTheme.of(context);
    final rowIndent = feedTheme?.rowIndent ?? 10;
    final child = switch (row) {
      TasklyHeaderRowSpec() => _HeaderRow(row: row),
      TasklySubheaderRowSpec() => _SubheaderRow(row: row),
      TasklyDividerRowSpec() => _DividerRow(),
      TasklyInlineActionRowSpec() => _InlineActionRow(row: row),
      TasklyValueHeaderRowSpec() => _ValueHeaderRow(row: row),
      TasklyTaskRowSpec() => _TaskRow(row: row),
      TasklyProjectRowSpec() => _ProjectRow(row: row),
      TasklyValueRowSpec() => _ValueRow(row: row),
      TasklyRoutineRowSpec() => _RoutineRow(row: row),
    };

    final key = switch (row) {
      TasklyHeaderRowSpec(:final key) => key,
      TasklySubheaderRowSpec(:final key) => key,
      TasklyDividerRowSpec(:final key) => key,
      TasklyInlineActionRowSpec(:final key) => key,
      TasklyValueHeaderRowSpec(:final key) => key,
      TasklyTaskRowSpec(:final key) => key,
      TasklyProjectRowSpec(:final key) => key,
      TasklyValueRowSpec(:final key) => key,
      TasklyRoutineRowSpec(:final key) => key,
    };

    final depth = switch (row) {
      TasklyHeaderRowSpec(:final depth) => depth,
      TasklySubheaderRowSpec(:final depth) => depth,
      TasklyDividerRowSpec(:final depth) => depth,
      TasklyInlineActionRowSpec(:final depth) => depth,
      TasklyValueHeaderRowSpec(:final depth) => depth,
      TasklyTaskRowSpec(:final depth) => depth,
      TasklyProjectRowSpec(:final depth) => depth,
      TasklyValueRowSpec() => 0,
      TasklyRoutineRowSpec(:final depth) => depth,
    };

    final indented = depth <= 0
        ? child
        : Padding(
            padding: EdgeInsets.only(left: depth * rowIndent),
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

    final hasValueHeaders = rows.any((row) => row is TasklyValueHeaderRowSpec);

    final children = hasValueHeaders
        ? _buildValueGroups(context, rows)
        : _buildFlatRows(context, rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

List<Widget> _buildFlatRows(BuildContext context, List<TasklyRowSpec> rows) {
  final children = <Widget>[];
  final feedTheme = TasklyFeedTheme.of(context);
  for (var i = 0; i < rows.length; i += 1) {
    final row = rows[i];
    children.add(TasklyFeedRenderer.buildRow(row, context: context));

    final isLast = i == rows.length - 1;
    if (isLast) continue;

    final spacing = _spacingAfter(row, feedTheme);
    if (spacing > 0) {
      children.add(SizedBox(height: spacing));
    }
  }
  return children;
}

List<Widget> _buildValueGroups(
  BuildContext context,
  List<TasklyRowSpec> rows,
) {
  final groups = <Widget>[];
  TasklyValueHeaderRowSpec? activeHeader;
  final buffer = <TasklyRowSpec>[];

  void flush() {
    if (activeHeader == null) return;
    groups.add(
      _ValueGroupSection(
        header: activeHeader,
        rows: List<TasklyRowSpec>.from(buffer),
      ),
    );
    buffer.clear();
  }

  for (final row in rows) {
    if (row is TasklyValueHeaderRowSpec) {
      flush();
      activeHeader = row;
      continue;
    }
    if (activeHeader == null) {
      groups.add(TasklyFeedRenderer.buildRow(row, context: context));
      continue;
    }
    buffer.add(row);
  }

  flush();

  return groups;
}

double _spacingAfter(TasklyRowSpec row, TasklyFeedTheme feedTheme) {
  return switch (row) {
    TasklyHeaderRowSpec() => 0,
    TasklySubheaderRowSpec() => 0,
    TasklyDividerRowSpec() => 0,
    TasklyInlineActionRowSpec() => feedTheme.entityRowSpacing,
    TasklyValueHeaderRowSpec() => feedTheme.entityRowSpacing,
    TasklyTaskRowSpec() => feedTheme.entityRowSpacing,
    TasklyProjectRowSpec() => feedTheme.entityRowSpacing,
    TasklyValueRowSpec() => feedTheme.entityRowSpacing,
    TasklyRoutineRowSpec() => feedTheme.entityRowSpacing,
  };
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.row});

  final TasklyHeaderRowSpec row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    final trailingStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (row.leadingIcon != null) ...[
              Icon(
                row.leadingIcon,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                row.title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (row.trailingLabel != null) ...[
              Text(row.trailingLabel!, style: trailingStyle),
              const SizedBox(width: 8),
            ],
            if (row.trailingIcon != null)
              Icon(row.trailingIcon, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: row.onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: row.onTap,
              child: content,
            ),
    );
  }
}

class _SubheaderRow extends StatelessWidget {
  const _SubheaderRow({required this.row});

  final TasklySubheaderRowSpec row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final titleStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            row.title,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ],
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

class _ValueHeaderRow extends StatelessWidget {
  const _ValueHeaderRow({required this.row});

  final TasklyValueHeaderRowSpec row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final chip = row.leadingChip;
    final priorityLabel = row.priorityLabel?.trim();

    final accentColor = chip?.color ?? scheme.primary;
    final iconData = chip?.icon ?? Icons.star_rounded;
    final backgroundOpacity = theme.brightness == Brightness.dark ? 0.2 : 0.12;
    final title = row.title.trim().toUpperCase();
    final priorityText = priorityLabel == null || priorityLabel.isEmpty
        ? null
        : priorityLabel.toUpperCase();

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: backgroundOpacity),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(tokens.sectionPaddingH, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(iconData, size: 18, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (priorityText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  priorityText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              row.isCollapsed
                  ? Icons.expand_more_rounded
                  : Icons.expand_less_rounded,
              size: 16,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth + tokens.sectionPaddingH * 2;
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: fullWidth,
              child: InkWell(
                onTap: row.onToggleCollapsed,
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ValueGroupSection extends StatelessWidget {
  const _ValueGroupSection({
    required this.header,
    required this.rows,
  });

  final TasklyValueHeaderRowSpec header;
  final List<TasklyRowSpec> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyEntityTileTheme.of(context);
    final hasRows = rows.isNotEmpty;
    final children = <Widget>[
      _ValueHeaderRow(row: header),
    ];

    if (hasRows && !header.isCollapsed) {
      children.add(const SizedBox(height: 8));
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.sectionPaddingH + 12,
            0,
            tokens.sectionPaddingH,
            8,
          ),
          child: Column(
            children: _buildFlatRows(context, rows),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.row});

  final TasklyTaskRowSpec row;

  @override
  Widget build(BuildContext context) {
    return TaskEntityTile(
      model: row.data,
      style: row.style,
      actions: row.actions,
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.row});

  final TasklyProjectRowSpec row;

  @override
  Widget build(BuildContext context) {
    return switch (row.preset) {
      TasklyProjectRowPresetGroupHeader(:final expanded) =>
        _ProjectGroupHeaderRow(
          data: row.data,
          actions: row.actions,
          expanded: expanded,
        ),
      _ => ProjectEntityTile(
        model: row.data,
        preset: row.preset,
        actions: row.actions,
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
    final hasTrailingLabel = trailingLabel != null && trailingLabel.isNotEmpty;

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
                trailingLabel,
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
      preset: row.preset,
      actions: row.actions,
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.row});

  final TasklyRoutineRowSpec row;

  @override
  Widget build(BuildContext context) {
    return RoutineEntityTile(
      model: row.data,
      actions: row.actions,
    );
  }
}

class _ScheduledDaySection extends StatelessWidget {
  const _ScheduledDaySection({
    required this.title,
    required this.countLabel,
    required this.rows,
    required this.emptyLabel,
    required this.onAddRequested,
  });

  final String title;
  final String? countLabel;
  final List<TasklyRowSpec> rows;
  final String? emptyLabel;
  final VoidCallback? onAddRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);
    final feedTheme = TasklyFeedTheme.of(context);

    final effectiveCount = countLabel?.trim();
    final hasCount = effectiveCount != null && effectiveCount.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        0,
        tokens.sectionPaddingH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: feedTheme.scheduledDayTitle.copyWith(
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasCount)
                  Text(
                    effectiveCount,
                    style: feedTheme.scheduledDayCount.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          _RowList(
            rows: rows,
            emptyLabel: emptyLabel,
            onAddRequested: onAddRequested,
          ),
        ],
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
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 18,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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
    final tokens = TasklyEntityTileTheme.of(context);
    final feedTheme = TasklyFeedTheme.of(context);

    final visibleRows = isCollapsed ? rows.take(3).toList() : rows;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        8,
        tokens.sectionPaddingH,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleCollapsed,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.error,
                      ),
                    ),
                  ),
                  Text(
                    countLabel,
                    style: feedTheme.scheduledOverdueCount.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
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
              padding: const EdgeInsets.only(bottom: 8),
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
    );
  }
}
