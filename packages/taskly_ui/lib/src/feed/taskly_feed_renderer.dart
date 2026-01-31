import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/sections/empty_state_widget.dart';
import 'package:taskly_ui/src/sections/feed_body.dart';
import 'package:taskly_ui/src/sections/value_distribution_section.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/entities/project_entity_tile.dart';
import 'package:taskly_ui/src/entities/routine_entity_tile.dart';
import 'package:taskly_ui/src/entities/task_entity_tile.dart';
import 'package:taskly_ui/src/entities/value_entity_tile.dart';

class TasklyFeedRenderer extends StatelessWidget {
  const TasklyFeedRenderer({
    required this.spec,
    this.controller,
    this.padding,
    this.entityRowPadding,
    super.key,
  });

  final TasklyFeedSpec spec;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? entityRowPadding;

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
            final tokens = TasklyTokens.of(context);
            return ListView.builder(
              controller: controller,
              padding: padding,
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final content = TasklyFeedRenderer.buildSection(
                  section,
                  entityRowPadding: entityRowPadding,
                );
                if (index == sections.length - 1) return content;
                return Padding(
                  padding: EdgeInsets.only(bottom: tokens.feedSectionSpacing),
                  child: content,
                );
              },
            );
          },
        ),
      ),
    };
  }

  static Widget buildSection(
    TasklySectionSpec section, {
    EdgeInsetsGeometry? entityRowPadding,
  }) {
    return switch (section) {
      TasklyStandardListSectionSpec(:final rows) => _RowList(
        rows: rows,
        emptyLabel: null,
        onAddRequested: null,
        entityRowPadding: entityRowPadding,
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
          entityRowPadding: entityRowPadding,
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
          entityRowPadding: entityRowPadding,
        ),
    };
  }

  static Widget buildRow(
    TasklyRowSpec row, {
    BuildContext? context,
    EdgeInsetsGeometry? entityRowPadding,
  }) {
    final tokens = context == null ? null : TasklyTokens.of(context);
    final rowIndent = tokens?.feedRowIndent ?? 10;
    final child = switch (row) {
      TasklyHeaderRowSpec() => _HeaderRow(row: row),
      TasklySubheaderRowSpec() => _SubheaderRow(row: row),
      TasklyDividerRowSpec() => _DividerRow(),
      TasklyInlineActionRowSpec() => _InlineActionRow(row: row),
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

    final rowPadding = entityRowPadding;
    final shouldPad =
        rowPadding != null &&
        switch (row) {
          TasklyTaskRowSpec() => true,
          TasklyProjectRowSpec() => true,
          TasklyValueRowSpec() => true,
          TasklyRoutineRowSpec() => true,
          _ => false,
        };

    final padded = shouldPad
        ? Padding(
            padding: rowPadding,
            child: indented,
          )
        : indented;

    final keyedRow = KeyedSubtree(key: ValueKey(key), child: padded);
    final anchorKey = switch (row) {
      TasklyHeaderRowSpec(:final anchorKey) => anchorKey,
      TasklySubheaderRowSpec(:final anchorKey) => anchorKey,
      TasklyDividerRowSpec(:final anchorKey) => anchorKey,
      TasklyInlineActionRowSpec(:final anchorKey) => anchorKey,
      TasklyTaskRowSpec(:final anchorKey) => anchorKey,
      TasklyProjectRowSpec(:final anchorKey) => anchorKey,
      TasklyValueRowSpec(:final anchorKey) => anchorKey,
      TasklyRoutineRowSpec(:final anchorKey) => anchorKey,
    };

    if (anchorKey == null) return keyedRow;
    return KeyedSubtree(key: anchorKey, child: keyedRow);
  }
}

class _RowList extends StatelessWidget {
  const _RowList({
    required this.rows,
    required this.emptyLabel,
    required this.onAddRequested,
    this.entityRowPadding,
  });

  final List<TasklyRowSpec> rows;
  final String? emptyLabel;
  final VoidCallback? onAddRequested;
  final EdgeInsetsGeometry? entityRowPadding;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && emptyLabel != null) {
      return _EmptyRow(
        label: emptyLabel!,
        onAddRequested: onAddRequested,
      );
    }

    final children = _buildFlatRows(
      context,
      rows,
      entityRowPadding: entityRowPadding,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

List<Widget> _buildFlatRows(
  BuildContext context,
  List<TasklyRowSpec> rows, {
  EdgeInsetsGeometry? entityRowPadding,
}) {
  final children = <Widget>[];
  final tokens = TasklyTokens.of(context);
  for (var i = 0; i < rows.length; i += 1) {
    final row = rows[i];
    children.add(
      TasklyFeedRenderer.buildRow(
        row,
        context: context,
        entityRowPadding: entityRowPadding,
      ),
    );

    final isLast = i == rows.length - 1;
    if (isLast) continue;

    final spacing = _spacingAfter(row, tokens);
    if (spacing > 0) {
      children.add(SizedBox(height: spacing));
    }
  }
  return children;
}

double _spacingAfter(TasklyRowSpec row, TasklyTokens tokens) {
  return switch (row) {
    TasklyHeaderRowSpec() => 0,
    TasklySubheaderRowSpec() => 0,
    TasklyDividerRowSpec() => 0,
    TasklyInlineActionRowSpec() => tokens.feedEntityRowSpacing,
    TasklyTaskRowSpec() => tokens.feedEntityRowSpacing,
    TasklyProjectRowSpec() => tokens.feedEntityRowSpacing,
    TasklyValueRowSpec() => tokens.feedEntityRowSpacing,
    TasklyRoutineRowSpec() => tokens.feedEntityRowSpacing,
  };
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.row});

  final TasklyHeaderRowSpec row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

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
                size: tokens.spaceLg2,
                color: scheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.spaceSm),
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
              SizedBox(width: tokens.spaceSm),
            ],
            if (row.trailingIcon != null)
              Icon(
                row.trailingIcon,
                size: tokens.spaceLg2,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        Container(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceXs2,
      ),
      child: row.onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(tokens.radiusSm),
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
    final tokens = TasklyTokens.of(context);

    final titleStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceSm2,
        tokens.sectionPaddingH,
        tokens.spaceXs2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            row.title,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: tokens.spaceXs2),
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
    final tokens = TasklyTokens.of(context);
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: tokens.sectionPaddingH),
      color: scheme.outlineVariant.withValues(alpha: 0.55),
    );
  }
}

class _InlineActionRow extends StatelessWidget {
  const _InlineActionRow({required this.row});

  final TasklyInlineActionRowSpec row;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.sectionPaddingH),
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
    return ProjectEntityTile(
      model: row.data,
      preset: row.preset,
      actions: row.actions,
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
      style: row.style,
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
    this.entityRowPadding,
  });

  final String title;
  final String? countLabel;
  final List<TasklyRowSpec> rows;
  final String? emptyLabel;
  final VoidCallback? onAddRequested;
  final EdgeInsetsGeometry? entityRowPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final tokens = TasklyTokens.of(context);

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
            padding: EdgeInsets.fromLTRB(
              tokens.spaceXs,
              0,
              tokens.spaceXs,
              tokens.spaceXs2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
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
                    style: textTheme.labelSmall?.copyWith(
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
          SizedBox(height: tokens.spaceSm2),
          _RowList(
            rows: rows,
            emptyLabel: emptyLabel,
            onAddRequested: onAddRequested,
            entityRowPadding: entityRowPadding,
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
    final tokens = TasklyTokens.of(context);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(tokens.radiusMd2),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceMd,
          tokens.spaceSm2,
          tokens.spaceMd,
          tokens.spaceSm2,
        ),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: tokens.spaceLg2,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            SizedBox(width: tokens.spaceSm),
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
                icon: Icon(Icons.add_rounded, size: tokens.spaceLg2),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceSm2,
                    vertical: tokens.spaceXs2,
                  ),
                  minimumSize: Size(0, tokens.minTapTargetSize),
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
    this.entityRowPadding,
  });

  final String title;
  final String countLabel;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;
  final List<TasklyRowSpec> rows;
  final String? actionLabel;
  final String? actionTooltip;
  final VoidCallback? onActionPressed;
  final EdgeInsetsGeometry? entityRowPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final tokens = TasklyTokens.of(context);

    final visibleRows = isCollapsed ? rows.take(3).toList() : rows;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceSm,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleCollapsed,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceXs,
                tokens.spaceXs2,
                tokens.spaceXs,
                tokens.spaceXs2,
              ),
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
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(width: tokens.spaceXs2),
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
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
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
                      entityRowPadding: entityRowPadding,
                    ),
            ),
        ],
      ),
    );
  }
}
