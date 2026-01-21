import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_ui/taskly_ui_entities.dart';

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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
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
              const SizedBox(height: 10),
            ],
            _BucketSection(
              title: context.l10n.myDayRitualOverdueDueTitle,
              acceptedTasks: widget.acceptedDue,
              counts: widget.dueCounts,
              expanded: _dueExpanded,
              onToggleExpanded: () =>
                  setState(() => _dueExpanded = !_dueExpanded),
              onTapOther: widget.onAddMissingDue,
              otherLabel: context.l10n.myDayRitualNotInTodayLabel,
              emptyTitle: widget.dueCounts.otherCount == 0
                  ? context.l10n.myDayRitualCaughtUpTitle
                  : context.l10n.myDayRitualNothingAddedHereYetTitle,
              emptySubtitle: widget.dueCounts.otherCount == 0
                  ? context.l10n.myDayRitualDueEmptySubtitle
                  : context.l10n.myDayRitualReviewAvailableAboveSubtitle,
              previewCount: _previewCount,
            ),
            if (!hideStartsSection) ...[
              const SizedBox(height: 10),
              _BucketSection(
                title: context.l10n.myDayRitualStartsTodayTitle,
                acceptedTasks: widget.acceptedStarts,
                counts: widget.startsCounts,
                expanded: _startsExpanded,
                onToggleExpanded: () =>
                    setState(() => _startsExpanded = !_startsExpanded),
                onTapOther: widget.onAddMissingStarts,
                otherLabel: context.l10n.myDayRitualNotInTodayLabel,
                emptyTitle: widget.startsCounts.otherCount == 0
                    ? context.l10n.myDayRitualStartsEmptyTitle
                    : context.l10n.myDayRitualNothingAddedHereYetTitle,
                emptySubtitle: widget.startsCounts.otherCount == 0
                    ? context.l10n.myDayRitualStartsEmptySubtitle
                    : context.l10n.myDayRitualReviewAvailableAboveSubtitle,
                previewCount: _previewCount,
              ),
            ],
            const SizedBox(height: 10),
            _BucketSection(
              title: context.l10n.myDayRitualTodaysFocusTitle,
              acceptedTasks: widget.acceptedFocus,
              counts: widget.focusCounts,
              expanded: _focusExpanded,
              onToggleExpanded: () =>
                  setState(() => _focusExpanded = !_focusExpanded),
              onTapOther: null,
              otherLabel: context.l10n.myDayRitualNotInTodayLabel,
              emptyTitle: context.l10n.myDayRitualFocusEmptyTitle,
              emptySubtitle: context.l10n.myDayRitualFocusEmptySubtitle,
              previewCount: _previewCount,
              subtitleForTask: (task) {
                final reason = widget.focusReasons[task.id];
                if (reason == null || reason.trim().isEmpty) return null;
                return reason;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketSection extends StatelessWidget {
  const _BucketSection({
    required this.title,
    required this.acceptedTasks,
    required this.counts,
    required this.expanded,
    required this.onToggleExpanded,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.previewCount,
    required this.otherLabel,
    this.onTapOther,
    this.subtitleForTask,
  });

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

  /// Optional per-task subtitle text.
  ///
  /// Returned string is rendered in the tile's subtitle slot.
  final String? Function(Task task)? subtitleForTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          if (!suppressCountsLine) ...[
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
          if (acceptedTasks.isEmpty)
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: suppressCountsLine ? onTapOther : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveEmptyTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        effectiveEmptySubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            for (final task in visible)
              _AcceptedTaskTile(
                task: task,
                subtitleText: subtitleForTask?.call(task),
              ),
            if (acceptedTasks.length > previewCount)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onToggleExpanded,
                    child: Text(
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

class _AcceptedTaskTile extends StatelessWidget {
  const _AcceptedTaskTile({required this.task, this.subtitleText});

  final Task task;
  final String? subtitleText;

  @override
  Widget build(BuildContext context) {
    final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);

    final selection = context.read<SelectionCubit>();
    final key = SelectionKey(entityType: EntityType.task, entityId: task.id);
    final selectionMode = selection.isSelectionMode;
    final isSelected = selection.isSelected(key);

    final model = buildTaskListRowTileModel(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
      showProjectLabel: false,
    );

    final subtitleText = this.subtitleText;

    return TaskEntityTile(
      model: model,
      intent: selectionMode
          ? TaskTileIntent.bulkSelection(selected: isSelected)
          : const TaskTileIntent.myDayList(),
      supportingText: subtitleText,
      markers: TaskTileMarkers(pinned: task.isPinned),
      actions: TaskTileActions(
        onTap: () {
          if (selection.shouldInterceptTapAsSelection()) {
            selection.handleEntityTap(key);
            return;
          }
          model.onTap();
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
        onOverflowMenuRequestedAt: null,
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
