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
    super.key,
    this.onReviewDue,
    this.onReviewStarts,
  });

  final List<Task> acceptedDue;
  final List<Task> acceptedStarts;
  final List<Task> acceptedFocus;

  final MyDayBucketCounts dueCounts;
  final MyDayBucketCounts startsCounts;

  final VoidCallback? onReviewDue;
  final VoidCallback? onReviewStarts;

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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            _BucketSection(
              title: 'Overdue & due',
              acceptedTasks: widget.acceptedDue,
              counts: widget.dueCounts,
              expanded: _dueExpanded,
              onToggleExpanded: () =>
                  setState(() => _dueExpanded = !_dueExpanded),
              onReview: widget.onReviewDue,
              emptyTitle: 'Nothing accepted here.',
              emptySubtitle: widget.dueCounts.otherCount > 0
                  ? "${widget.dueCounts.otherCount} other overdue item${widget.dueCounts.otherCount == 1 ? '' : 's'} not in today's plan."
                  : 'No accepted overdue items for today.',
              previewCount: _previewCount,
            ),
            const SizedBox(height: 10),
            _BucketSection(
              title: 'Starts today',
              acceptedTasks: widget.acceptedStarts,
              counts: widget.startsCounts,
              expanded: _startsExpanded,
              onToggleExpanded: () =>
                  setState(() => _startsExpanded = !_startsExpanded),
              onReview: widget.onReviewStarts,
              emptyTitle: 'Nothing accepted here.',
              emptySubtitle: widget.startsCounts.otherCount > 0
                  ? "${widget.startsCounts.otherCount} other item${widget.startsCounts.otherCount == 1 ? '' : 's'} starting (or due soon) not in today's plan."
                  : 'No accepted start items for today.',
              previewCount: _previewCount,
            ),
            const SizedBox(height: 10),
            _BucketSection(
              title: 'Today’s Focus',
              acceptedTasks: widget.acceptedFocus,
              counts: MyDayBucketCounts(
                acceptedCount: widget.acceptedFocus.length,
                otherCount: 0,
              ),
              expanded: _focusExpanded,
              onToggleExpanded: () =>
                  setState(() => _focusExpanded = !_focusExpanded),
              onReview: null,
              emptyTitle: 'Nothing accepted here.',
              emptySubtitle: 'No focus items accepted for today.',
              previewCount: _previewCount,
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
    this.onReview,
  });

  final String title;
  final List<Task> acceptedTasks;
  final MyDayBucketCounts counts;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onReview;
  final String emptyTitle;
  final String emptySubtitle;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final visible = expanded
        ? acceptedTasks
        : acceptedTasks.take(previewCount).toList(growable: false);
    final remaining = acceptedTasks.length - visible.length;

    final showReview = (counts.otherCount > 0) && onReview != null;

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
              if (showReview)
                TextButton(
                  onPressed: onReview,
                  child: Text(
                    'Review',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${counts.acceptedCount} accepted'
            '${counts.otherCount > 0 ? ' · ${counts.otherCount} other' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (acceptedTasks.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emptyTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emptySubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (final task in visible) _AcceptedTaskTile(task: task),
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
  const _AcceptedTaskTile({required this.task});

  final Task task;

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

    return TaskEntityTile(
      model: model,
      onTap: model.onTap,
      trailing: hasAnyEnabledAction
          ? TrailingSpec.overflowButton
          : TrailingSpec.none,
      onToggleCompletion: buildTaskToggleCompletionHandler(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
      ),
      onOverflowRequestedAt: hasAnyEnabledAction
          ? (pos) => showTileOverflowMenu(
              context,
              position: pos,
              entityTypeLabel: 'task',
              entityId: task.id,
              actions: overflowActions,
            )
          : null,
    );
  }
}
