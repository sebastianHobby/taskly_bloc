import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_menu.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
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

    final hideStartsSection =
        widget.acceptedStarts.isEmpty &&
        widget.startsCounts.acceptedCount == 0 &&
        widget.startsCounts.otherCount == 0;

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
                            'All set for today.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You completed everything you planned today.',
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
                          label: const Text('Add one more focus'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            _BucketSection(
              title: 'Overdue & due',
              acceptedTasks: widget.acceptedDue,
              counts: widget.dueCounts,
              expanded: _dueExpanded,
              onToggleExpanded: () =>
                  setState(() => _dueExpanded = !_dueExpanded),
              onTapOther: widget.onAddMissingDue,
              otherLabel: 'not in today',
              emptyTitle: widget.dueCounts.otherCount == 0
                  ? "You're caught up."
                  : 'Nothing added here yet.',
              emptySubtitle: widget.dueCounts.otherCount == 0
                  ? 'No overdue or due items in your plan.'
                  : 'Review what’s available above if you want to add any.',
              previewCount: _previewCount,
            ),
            if (!hideStartsSection) ...[
              const SizedBox(height: 10),
              _BucketSection(
                title: 'Starts today',
                acceptedTasks: widget.acceptedStarts,
                counts: widget.startsCounts,
                expanded: _startsExpanded,
                onToggleExpanded: () =>
                    setState(() => _startsExpanded = !_startsExpanded),
                onTapOther: widget.onAddMissingStarts,
                otherLabel: 'not in today',
                emptyTitle: widget.startsCounts.otherCount == 0
                    ? 'Nothing scheduled to start today.'
                    : 'Nothing added here yet.',
                emptySubtitle: widget.startsCounts.otherCount == 0
                    ? 'This section will appear when tasks become available.'
                    : 'Review what’s available above if you want to add any.',
                previewCount: _previewCount,
              ),
            ],
            const SizedBox(height: 10),
            _BucketSection(
              title: 'Today’s Focus',
              acceptedTasks: widget.acceptedFocus,
              counts: widget.focusCounts,
              expanded: _focusExpanded,
              onToggleExpanded: () =>
                  setState(() => _focusExpanded = !_focusExpanded),
              onTapOther: null,
              otherLabel: 'not in today',
              emptyTitle: 'Nothing accepted here.',
              emptySubtitle: 'No focus items accepted for today.',
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
        ? 'Nothing added yet.'
        : emptyTitle;

    final effectiveEmptySubtitle = suppressCountsLine
        ? () {
            final otherCount = counts.otherCount;
            final n = otherCount == 1 ? '1 task' : '$otherCount tasks';
            return '$n not in today. Tap to review and add.';
          }()
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
                          ? 'Show fewer'
                          : 'Show $remaining more (${acceptedTasks.length})',
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

    final overflowActions = TileOverflowActionCatalog.forTask(
      taskId: task.id,
      taskName: task.name,
      isPinnedToMyDay: task.isPinned,
      isRepeating: task.isRepeating,
      seriesEnded: task.seriesEnded,
      tileCapabilities: tileCapabilities,
    );

    final hasAnyEnabledAction = overflowActions.any((a) => a.enabled);

    final model = buildTaskListRowTileModel(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
      showProjectLabel: true,
    );

    final subtitleText = this.subtitleText;

    return TaskEntityTile(
      model: model,
      supportingText: subtitleText,
      markers: TaskTileMarkers(pinned: task.isPinned),
      actions: TaskTileActions(
        onTap: model.onTap,
        onToggleCompletion: buildTaskToggleCompletionHandler(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        ),
        onOverflowMenuRequestedAt: hasAnyEnabledAction
            ? (pos) => showTileOverflowMenu(
                context,
                position: pos,
                entityTypeLabel: 'task',
                entityId: task.id,
                actions: overflowActions,
              )
            : null,
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
          TextSpan(text: '$acceptedCount accepted'),
          if (otherCount > 0) const TextSpan(text: ' · '),
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
                        '$otherCount $otherLabel',
                        style: chipTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (otherCount > 0)
            TextSpan(text: '$otherCount $otherLabel'),
        ],
      ),
    );
  }
}
