import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_renderer.dart';
import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

final class TasklyMyDayEmptyState {
  const TasklyMyDayEmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

final class TasklyMyDaySectionList {
  const TasklyMyDaySectionList({
    required this.id,
    required this.rows,
    this.footer,
  });

  final String id;
  final List<TasklyRowSpec> rows;
  final Widget? footer;
}

final class TasklyMyDaySectionConfig {
  const TasklyMyDaySectionConfig({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggleExpanded,
    required this.list,
    required this.emptyState,
    this.headerKey,
    this.icon,
    this.showCount = true,
    this.subtitle,
    this.action,
    this.showEmpty = true,
    this.iconBadge = false,
  });

  final Key? headerKey;
  final String title;
  final IconData? icon;
  final bool iconBadge;
  final int count;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final TasklyMyDaySectionList list;
  final TasklyMyDayEmptyState emptyState;
  final bool showCount;
  final String? subtitle;
  final Widget? action;
  final bool showEmpty;
}

final class TasklyMyDaySubsectionConfig {
  const TasklyMyDaySubsectionConfig({
    required this.title,
    required this.icon,
    required this.count,
    required this.expanded,
    required this.onToggleExpanded,
    required this.list,
    required this.emptyState,
    this.iconColor,
    this.showEmpty = true,
    this.countLine,
  });

  final String title;
  final IconData icon;
  final int count;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final TasklyMyDaySectionList list;
  final TasklyMyDayEmptyState emptyState;
  final Color? iconColor;
  final bool showEmpty;
  final TasklyMyDayCountLine? countLine;
}

final class TasklyMyDayTimeSensitiveConfig {
  const TasklyMyDayTimeSensitiveConfig({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggleExpanded,
    required this.due,
    required this.planned,
    this.headerKey,
    this.showCount = true,
    this.subtitle,
  });

  final Key? headerKey;
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final TasklyMyDaySubsectionConfig due;
  final TasklyMyDaySubsectionConfig planned;
  final bool showCount;
  final String? subtitle;
}

final class TasklyMyDayCountLine {
  const TasklyMyDayCountLine({
    required this.acceptedCount,
    required this.acceptedLabel,
    required this.otherCount,
    required this.otherLabel,
    this.onTapOther,
  });

  final int acceptedCount;
  final String acceptedLabel;
  final int otherCount;
  final String otherLabel;
  final VoidCallback? onTapOther;
}

class TasklyMyDaySectionStack extends StatelessWidget {
  const TasklyMyDaySectionStack({
    required this.valuesAligned,
    required this.completed,
    this.pinned,
    this.timeSensitive,
    super.key,
  });

  final TasklyMyDaySectionConfig? pinned;
  final TasklyMyDaySectionConfig valuesAligned;
  final TasklyMyDayTimeSensitiveConfig? timeSensitive;
  final TasklyMyDaySectionConfig completed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final pinned = this.pinned;
    final pinnedConfig = pinned;
    final timeSensitive = this.timeSensitive;
    final showTimeSensitive =
        timeSensitive != null &&
        (timeSensitive.due.list.rows.isNotEmpty ||
            timeSensitive.planned.list.rows.isNotEmpty ||
            timeSensitive.due.showEmpty ||
            timeSensitive.planned.showEmpty);
    final showCompleted = completed.list.rows.isNotEmpty || completed.showEmpty;

    final sections = <Widget>[];

    void addDivider() {
      sections.addAll([
        SizedBox(height: tokens.spaceMd),
        Divider(color: cs.outlineVariant.withOpacity(0.35), height: 1),
        SizedBox(height: tokens.spaceMd),
      ]);
    }

    void addSection(List<Widget> widgets) {
      if (sections.isNotEmpty) {
        addDivider();
      }
      sections.addAll(widgets);
    }

    if (pinnedConfig != null &&
        (pinnedConfig.list.rows.isNotEmpty || pinnedConfig.showEmpty)) {
      addSection([
        _SectionHeader(
          key: pinnedConfig.headerKey,
          title: pinnedConfig.title,
          icon: pinnedConfig.icon,
          count: pinnedConfig.count,
          showCount: pinnedConfig.showCount,
          subtitle: pinnedConfig.subtitle,
          action: pinnedConfig.action,
          iconBadge: pinnedConfig.iconBadge,
          expanded: pinnedConfig.expanded,
          onToggleExpanded: pinnedConfig.onToggleExpanded,
        ),
        if (pinnedConfig.expanded)
          _SectionBody(
            list: pinnedConfig.list,
            emptyState: pinnedConfig.emptyState,
            showEmpty: pinnedConfig.showEmpty,
          ),
      ]);
    }

    addSection([
      _SectionHeader(
        key: valuesAligned.headerKey,
        title: valuesAligned.title,
        icon: valuesAligned.icon,
        count: valuesAligned.count,
        showCount: valuesAligned.showCount,
        subtitle: valuesAligned.subtitle,
        action: valuesAligned.action,
        iconBadge: valuesAligned.iconBadge,
        expanded: valuesAligned.expanded,
        onToggleExpanded: valuesAligned.onToggleExpanded,
      ),
      if (valuesAligned.expanded)
        _SectionBody(
          list: valuesAligned.list,
          emptyState: valuesAligned.emptyState,
          showEmpty: valuesAligned.showEmpty,
        ),
    ]);

    if (showTimeSensitive) {
      addSection([
        _SectionHeader(
          key: timeSensitive.headerKey,
          title: timeSensitive.title,
          icon: timeSensitive.icon,
          count: timeSensitive.due.count + timeSensitive.planned.count,
          showCount: timeSensitive.showCount,
          subtitle: timeSensitive.subtitle,
          iconBadge: false,
          expanded: timeSensitive.expanded,
          onToggleExpanded: timeSensitive.onToggleExpanded,
        ),
        if (timeSensitive.expanded) ...[
          SizedBox(height: tokens.spaceXs2),
          _Subsection(
            title: timeSensitive.due.title,
            icon: timeSensitive.due.icon,
            iconColor: timeSensitive.due.iconColor,
            count: timeSensitive.due.count,
            expanded: timeSensitive.due.expanded,
            onToggleExpanded: timeSensitive.due.onToggleExpanded,
            list: timeSensitive.due.list,
            emptyState: timeSensitive.due.emptyState,
            showEmpty: timeSensitive.due.showEmpty,
            countLine: timeSensitive.due.countLine,
          ),
          SizedBox(height: tokens.spaceSm2),
          _Subsection(
            title: timeSensitive.planned.title,
            icon: timeSensitive.planned.icon,
            iconColor: timeSensitive.planned.iconColor,
            count: timeSensitive.planned.count,
            expanded: timeSensitive.planned.expanded,
            onToggleExpanded: timeSensitive.planned.onToggleExpanded,
            list: timeSensitive.planned.list,
            emptyState: timeSensitive.planned.emptyState,
            showEmpty: timeSensitive.planned.showEmpty,
            countLine: timeSensitive.planned.countLine,
          ),
        ],
      ]);
    }

    if (showCompleted) {
      addSection([
        _SectionHeader(
          title: completed.title,
          icon: completed.icon,
          count: completed.count,
          showCount: completed.showCount,
          action: completed.action,
          iconBadge: completed.iconBadge,
          expanded: completed.expanded,
          onToggleExpanded: completed.onToggleExpanded,
        ),
        if (completed.expanded)
          _SectionBody(
            list: completed.list,
            emptyState: completed.emptyState,
            showEmpty: completed.showEmpty,
          ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.showCount,
    required this.expanded,
    required this.onToggleExpanded,
    required this.iconBadge,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final IconData? icon;
  final bool iconBadge;
  final int count;
  final bool showCount;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final actionOnSubtitle = hasSubtitle && action != null;
    final tokens = TasklyTokens.of(context);
    final subtitleIndent = tokens.spaceXl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              if (iconBadge)
                Container(
                  width: tokens.spaceXl,
                  height: tokens.spaceXl,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(tokens.radiusPill),
                  ),
                  child: Icon(icon, size: tokens.spaceLg, color: cs.primary),
                )
              else
                Icon(icon, size: tokens.spaceLg, color: cs.primary),
              SizedBox(width: tokens.spaceSm),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (showCount)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceXs2,
                  vertical: tokens.spaceXxs,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            if (!actionOnSubtitle && action != null) ...[
              SizedBox(width: tokens.spaceSm),
              action!,
            ],
            IconButton(
              onPressed: onToggleExpanded,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            ),
          ],
        ),
        if (hasSubtitle) ...[
          SizedBox(height: tokens.spaceXxs),
          Padding(
            padding: EdgeInsets.only(left: icon == null ? 0 : subtitleIndent),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (actionOnSubtitle) ...[
                  SizedBox(width: tokens.spaceSm),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.list,
    required this.emptyState,
    required this.showEmpty,
  });

  final TasklyMyDaySectionList list;
  final TasklyMyDayEmptyState emptyState;
  final bool showEmpty;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    if (list.rows.isEmpty && !showEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: tokens.spaceXs2),
        if (list.rows.isEmpty)
          _EmptyPanel(
            title: emptyState.title,
            description: emptyState.description,
          )
        else
          TasklyFeedRenderer.buildSection(
            TasklySectionSpec.standardList(
              id: list.id,
              rows: list.rows,
            ),
          ),
        if (list.footer != null) list.footer!,
      ],
    );
  }
}

class _Subsection extends StatelessWidget {
  const _Subsection({
    required this.title,
    required this.icon,
    required this.count,
    required this.expanded,
    required this.onToggleExpanded,
    required this.list,
    required this.emptyState,
    required this.showEmpty,
    this.iconColor,
    this.countLine,
  });

  final String title;
  final IconData icon;
  final int count;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final TasklyMyDaySectionList list;
  final TasklyMyDayEmptyState emptyState;
  final Color? iconColor;
  final bool showEmpty;
  final TasklyMyDayCountLine? countLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    if (list.rows.isEmpty && !showEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.sectionPaddingH,
            tokens.spaceSm2,
            tokens.sectionPaddingH,
            tokens.spaceXs2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(width: tokens.spaceXs),
                  IconButton(
                    onPressed: onToggleExpanded,
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceXs2),
              Container(
                height: 1,
                color: cs.outlineVariant.withOpacity(0.45),
              ),
            ],
          ),
        ),
        if (expanded && countLine != null)
          _CountsLine(
            acceptedCount: countLine!.acceptedCount,
            acceptedLabel: countLine!.acceptedLabel,
            otherCount: countLine!.otherCount,
            otherLabel: countLine!.otherLabel,
            onTapOther: countLine!.onTapOther,
          ),
        if (expanded && countLine != null) SizedBox(height: tokens.spaceSm),
        if (expanded)
          if (list.rows.isEmpty)
            _EmptyPanel(
              title: emptyState.title,
              description: emptyState.description,
            )
          else
            TasklyFeedRenderer.buildSection(
              TasklySectionSpec.standardList(
                id: list.id,
                rows: list.rows,
              ),
            ),
        if (expanded && list.footer != null) list.footer!,
      ],
    );
  }
}

class _CountsLine extends StatelessWidget {
  const _CountsLine({
    required this.acceptedCount,
    required this.acceptedLabel,
    required this.otherCount,
    required this.otherLabel,
    this.onTapOther,
  });

  final int acceptedCount;
  final String acceptedLabel;
  final int otherCount;
  final String otherLabel;
  final VoidCallback? onTapOther;

  @override
  Widget build(BuildContext context) {
    if (acceptedCount == 0 && otherCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final chipTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w800,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: acceptedLabel),
          if (otherCount > 0) const TextSpan(text: ' \u00b7 '),
          if (otherCount > 0)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTapOther,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(tokens.radiusPill),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceSm,
                        vertical: tokens.spaceXxs,
                      ),
                      child: Text(
                        '$otherCount $otherLabel',
                        style: chipTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceXs2,
        tokens.sectionPaddingH,
        tokens.spaceXs2,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          tokens.spaceMd,
          tokens.spaceSm2,
          tokens.spaceMd,
          tokens.spaceSm2,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: tokens.spaceLg2,
              color: cs.onSurfaceVariant,
            ),
            SizedBox(width: tokens.spaceSm2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spaceXxs),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
