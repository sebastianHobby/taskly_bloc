import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_ui/taskly_ui_feed.dart';

final class MyDayBucketCounts {
  const MyDayBucketCounts({
    required this.acceptedCount,
    required this.otherCount,
  });

  final int acceptedCount;

  /// Count of items in the bucket universe that are NOT in today's plan.
  ///
  /// This intentionally avoids claiming "all caught up" globally.
  final int otherCount;
}

class MyDayRitualSectionsCard extends StatefulWidget {
  const MyDayRitualSectionsCard({
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    required this.dueCounts,
    required this.startsCounts,
    required this.focusCounts,
    required this.showCompletionMessage,
    this.focusReasons = const <String, String>{},
    super.key,
    this.onAddMissingDue,
    this.onAddMissingStarts,
    this.onAddOneMoreFocus,
    this.onWhyThese,
  });

  final List<Task> acceptedDue;
  final List<Task> acceptedStarts;
  final List<Task> acceptedFocus;

  final MyDayBucketCounts dueCounts;
  final MyDayBucketCounts startsCounts;
  final MyDayBucketCounts focusCounts;

  final bool showCompletionMessage;

  /// Optional reason text for focus tasks, keyed by task id.
  ///
  /// When empty or when a task id is missing, no subtitle is shown.
  final Map<String, String> focusReasons;

  final VoidCallback? onAddMissingDue;
  final VoidCallback? onAddMissingStarts;
  final VoidCallback? onAddOneMoreFocus;
  final VoidCallback? onWhyThese;

  @override
  State<MyDayRitualSectionsCard> createState() =>
      _MyDayRitualSectionsCardState();
}

class _MyDayRitualSectionsCardState extends State<MyDayRitualSectionsCard> {
  static const _previewCount = 6;

  bool _dueExpanded = false;
  bool _startsExpanded = false;
  bool _focusExpanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final selection = context.read<SelectionCubit>();

    final hideStartsSection =
        widget.acceptedStarts.isEmpty &&
        widget.startsCounts.acceptedCount == 0 &&
        widget.startsCounts.otherCount == 0;

    void registerVisibleTasks(List<Task> tasks) {
      selection.updateVisibleEntities(
        tasks
            .map(
              (t) => SelectionEntityMeta(
                key: SelectionKey(
                  entityType: EntityType.task,
                  entityId: t.id,
                ),
                displayName: t.name,
                canDelete: true,
                completed: t.completed,
                pinned: t.isPinned,
                canCompleteSeries: t.isRepeating && !t.seriesEnded,
              ),
            )
            .toList(growable: false),
      );
    }

    final dueVisible = _dueExpanded
        ? widget.acceptedDue
        : widget.acceptedDue.take(_previewCount).toList(growable: false);
    final startsVisible = hideStartsSection
        ? const <Task>[]
        : _startsExpanded
        ? widget.acceptedStarts
        : widget.acceptedStarts.take(_previewCount).toList(growable: false);
    final focusVisible = _focusExpanded
        ? widget.acceptedFocus
        : widget.acceptedFocus.take(_previewCount).toList(growable: false);

    registerVisibleTasks(<Task>[
      ...dueVisible,
      ...startsVisible,
      ...focusVisible,
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showCompletionMessage) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.myDayRitualAllSetTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.myDayRitualAllSetSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.onAddOneMoreFocus != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onAddOneMoreFocus,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.l10n.myDayRitualAddOneMoreFocus),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SectionHeader(
          icon: Icons.eco_rounded,
          title: l10n.myDayWhatMattersSectionTitle,
          count: widget.focusCounts.acceptedCount,
          subtitle: '',
          showCount: false,
          actionLabel: l10n.myDayWhyTheseAction,
          onAction: widget.onWhyThese,
        ),
        if (widget.acceptedFocus.isNotEmpty) ...[
          const SizedBox(height: 6),
          _BucketSection(
            icon: Icons.wb_sunny_outlined,
            title: l10n.myDayRitualTodaysFocusTitle,
            acceptedTasks: widget.acceptedFocus,
            counts: widget.focusCounts,
            expanded: _focusExpanded,
            showHeader: false,
            showCountsLine: false,
            showEmpty: false,
            onToggleExpanded: () =>
                setState(() => _focusExpanded = !_focusExpanded),
            onTapOther: null,
            otherLabel: l10n.myDayRitualNotInTodayLabel,
            emptyTitle: l10n.myDayRitualFocusEmptyTitle,
            emptySubtitle: l10n.myDayRitualFocusEmptySubtitle,
            previewCount: _previewCount,
            subtitleForTask: (task) {
              final reason = widget.focusReasons[task.id];
              if (reason == null || reason.trim().isEmpty) return null;
              return reason;
            },
          ),
        ],
        const SizedBox(height: 12),
        Divider(color: cs.outlineVariant.withOpacity(0.5), height: 1),
        const SizedBox(height: 12),
        _SectionHeader(
          icon: Icons.access_time_rounded,
          title: l10n.myDayWhatsWaitingSectionTitle,
          count: widget.dueCounts.otherCount + widget.startsCounts.otherCount,
          subtitle: '',
          showCount: false,
        ),
        const SizedBox(height: 6),
        _BucketSection(
          icon: Icons.warning_rounded,
          title: l10n.myDayDueSoonLabel,
          acceptedTasks: widget.acceptedDue,
          counts: widget.dueCounts,
          expanded: _dueExpanded,
          onToggleExpanded: () => setState(() => _dueExpanded = !_dueExpanded),
          useCompactHeader: true,
          headerIconColor: cs.error,
          onTapOther: widget.onAddMissingDue,
          otherLabel: l10n.myDayRitualNotInTodayLabel,
          emptyTitle: widget.dueCounts.otherCount == 0
              ? l10n.myDayRitualCaughtUpTitle
              : l10n.myDayRitualNothingAddedHereYetTitle,
          emptySubtitle: widget.dueCounts.otherCount == 0
              ? l10n.myDayRitualDueEmptySubtitle
              : l10n.myDayRitualReviewAvailableAboveSubtitle,
          previewCount: _previewCount,
          showCountsLine: false,
        ),
        if (!hideStartsSection) ...[
          const SizedBox(height: 10),
          _BucketSection(
            icon: Icons.event_note_rounded,
            title: l10n.myDayAvailableToStartLabel,
            acceptedTasks: widget.acceptedStarts,
            counts: widget.startsCounts,
            expanded: _startsExpanded,
            onToggleExpanded: () =>
                setState(() => _startsExpanded = !_startsExpanded),
            useCompactHeader: true,
            compactLabel: l10n.myDayPlannedSectionTitle,
            headerIconColor: cs.secondary,
            onTapOther: widget.onAddMissingStarts,
            otherLabel: l10n.myDayRitualNotInTodayLabel,
            emptyTitle: widget.startsCounts.otherCount == 0
                ? l10n.myDayRitualStartsEmptyTitle
                : l10n.myDayRitualNothingAddedHereYetTitle,
            emptySubtitle: widget.startsCounts.otherCount == 0
                ? l10n.myDayRitualStartsEmptySubtitle
                : l10n.myDayRitualReviewAvailableAboveSubtitle,
            previewCount: _previewCount,
            showCountsLine: false,
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.subtitle,
    this.showCount = true,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final int count;
  final String subtitle;
  final bool showCount;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final separator = context.l10n.dotSeparator;
    final combinedTitle = subtitle.trim().isEmpty
        ? title
        : '$title$separator$subtitle';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              combinedTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showCount)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _BucketSection extends StatelessWidget {
  const _BucketSection({
    required this.icon,
    required this.title,
    required this.acceptedTasks,
    required this.counts,
    required this.expanded,
    required this.onToggleExpanded,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.previewCount,
    required this.otherLabel,
    this.showHeader = true,
    this.showCountsLine = true,
    this.showEmpty = true,
    this.onTapOther,
    this.subtitleForTask,
    this.useCompactHeader = false,
    this.compactLabel,
    this.headerIconColor,
  });

  final IconData icon;
  final String title;
  final List<Task> acceptedTasks;
  final MyDayBucketCounts counts;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String otherLabel;
  final VoidCallback? onTapOther;
  final String emptyTitle;
  final String emptySubtitle;
  final int previewCount;
  final bool showHeader;
  final bool showCountsLine;
  final bool showEmpty;
  final bool useCompactHeader;
  final String? compactLabel;
  final Color? headerIconColor;

  /// Optional per-task subtitle text.
  ///
  /// Returned string is rendered in the tile's subtitle slot.
  final String? Function(Task task)? subtitleForTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final universeCount = counts.acceptedCount + counts.otherCount;

    final visible = expanded
        ? acceptedTasks
        : acceptedTasks.take(previewCount).toList(growable: false);
    final remaining = acceptedTasks.length - visible.length;

    final showOtherLink = counts.otherCount > 0 && onTapOther != null;

    final suppressCountsLine =
        acceptedTasks.isEmpty &&
        counts.acceptedCount == 0 &&
        counts.otherCount > 0;

    final effectiveEmptyTitle = suppressCountsLine
        ? context.l10n.myDayRitualNothingAddedYetTitle
        : emptyTitle;

    final effectiveEmptySubtitle = suppressCountsLine
        ? context.l10n.myDayRitualOtherNotInTodayHint(counts.otherCount)
        : emptySubtitle;

    TasklyRowSpec buildRow(Task task) {
      final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);

      final selection = context.read<SelectionCubit>();
      final key = SelectionKey(entityType: EntityType.task, entityId: task.id);
      final selectionMode = selection.isSelectionMode;
      final isSelected = selection.isSelected(key);

      final data = buildTaskRowData(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
      );

      final openEditor = buildTaskOpenEditorHandler(context, task: task);

      final labels = TasklyTaskRowLabels(
        pinnedSemanticLabel: context.l10n.pinnedSemanticLabel,
      );

      final updatedData = TasklyTaskRowData(
        id: data.id,
        title: data.title,
        completed: data.completed,
        meta: data.meta,
        leadingChip: data.leadingChip,
        secondaryChips: data.secondaryChips,
        supportingText: subtitleForTask?.call(task),
        supportingTooltipText: null,
        deemphasized: data.deemphasized,
        checkboxSemanticLabel: data.checkboxSemanticLabel,
        labels: labels,
      );

      return TasklyRowSpec.task(
        key: 'myday-accepted-${task.id}',
        data: updatedData,
        preset: selectionMode
            ? TasklyTaskRowPreset.bulkSelection(selected: isSelected)
            : const TasklyTaskRowPreset.standard(),
        markers: TasklyTaskRowMarkers(
          pinned: task.isPinned,
        ),
        actions: TasklyTaskRowActions(
          onTap: () {
            if (selection.shouldInterceptTapAsSelection()) {
              selection.handleEntityTap(key);
              return;
            }
            openEditor();
          },
          onLongPress: () {
            selection.enterSelectionMode(initialSelection: key);
          },
          onToggleSelected: () => selection.toggleSelection(
            key,
            extendRange: false,
          ),
          onToggleCompletion: buildTaskToggleCompletionHandler(
            context,
            task: task,
            tileCapabilities: tileCapabilities,
          ),
        ),
      );
    }

    final rows = visible.map(buildRow).toList(growable: false);

    if (!showEmpty && acceptedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: headerIconColor ?? cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: useCompactHeader
                      ? Text(
                          '${(compactLabel ?? title).toUpperCase()} ($universeCount)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        )
                      : Text(
                          '$title${context.l10n.dotSeparator}$universeCount',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (showCountsLine && !suppressCountsLine) ...[
              _CountsLine(
                acceptedCount: counts.acceptedCount,
                otherCount: counts.otherCount,
                otherLabel: otherLabel,
                showOtherAsLink: showOtherLink,
                onTapOther: onTapOther,
              ),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: 10),
          ],
          if (acceptedTasks.isEmpty)
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: suppressCountsLine ? onTapOther : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              effectiveEmptyTitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              effectiveEmptySubtitle,
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
              ),
            )
          else ...[
            TasklyFeedRenderer.buildSection(
              TasklySectionSpec.standardList(
                id: 'myday-accepted',
                rows: rows,
              ),
            ),
            if (acceptedTasks.length > previewCount)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: TextButton.icon(
                    onPressed: onToggleExpanded,
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    label: Text(
                      expanded
                          ? context.l10n.myDayRitualShowFewer
                          : context.l10n.myDayRitualShowMore(
                              remaining,
                              acceptedTasks.length,
                            ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CountsLine extends StatelessWidget {
  const _CountsLine({
    required this.acceptedCount,
    required this.otherCount,
    required this.otherLabel,
    required this.showOtherAsLink,
    this.onTapOther,
  });

  final int acceptedCount;
  final int otherCount;
  final String otherLabel;
  final bool showOtherAsLink;
  final VoidCallback? onTapOther;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          TextSpan(text: context.l10n.myDayRitualAcceptedCount(acceptedCount)),
          if (otherCount > 0) TextSpan(text: context.l10n.dotSeparator),
          if (otherCount > 0 && showOtherAsLink)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTapOther,
                  borderRadius: BorderRadius.circular(999),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        context.l10n.countWithLabel(otherCount, otherLabel),
                        style: chipTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (otherCount > 0)
            TextSpan(text: context.l10n.countWithLabel(otherCount, otherLabel)),
        ],
      ),
    );
  }
}
