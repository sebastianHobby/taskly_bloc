import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_progress.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_item.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/workflow_progress_bar.dart';

/// Renders support blocks that provide contextual insights during workflows.
class SupportBlocksSection extends StatelessWidget {
  const SupportBlocksSection({
    required this.blocks,
    required this.items,
    required this.supportBlockComputer,
    super.key,
  });

  final List<SupportBlock> blocks;
  final List<WorkflowItem<Task>> items;
  final SupportBlockComputer supportBlockComputer;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    final tasks = items.map((item) => item.entity).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Insights',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: blocks
                .map(
                  (block) => SupportBlockCard(
                    block: block,
                    items: items,
                    tasks: tasks,
                    supportBlockComputer: supportBlockComputer,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Individual support block renderer.
class SupportBlockCard extends StatelessWidget {
  const SupportBlockCard({
    required this.block,
    required this.items,
    required this.tasks,
    required this.supportBlockComputer,
    super.key,
  });

  final SupportBlock block;
  final List<WorkflowItem<Task>> items;
  final List<Task> tasks;
  final SupportBlockComputer supportBlockComputer;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      TaskStatsBlock(:final statType, :final range) => _TaskStatsCard(
        statType: statType,
        range: range,
        supportBlockComputer: supportBlockComputer,
        tasks: tasks,
      ),
      WorkflowProgressBlock() => _WorkflowProgressCard(items: items),
      BreakdownBlock(
        :final dimension,
        :final maxItems,
        :final statType,
        :final range,
      ) =>
        _BreakdownCard(
          dimension: dimension,
          statType: statType,
          range: range,
          maxItems: maxItems,
          supportBlockComputer: supportBlockComputer,
          tasks: tasks,
        ),
      FilteredListBlock(:final title, :final maxItems) => _FilteredListCard(
        title: title,
        maxItems: maxItems,
        block: block as FilteredListBlock,
        supportBlockComputer: supportBlockComputer,
        tasks: tasks,
      ),
      MoodCorrelationBlock(:final statType, :final range) =>
        _MoodCorrelationCard(
          statType: statType,
          range: range,
          supportBlockComputer: supportBlockComputer,
          tasks: tasks,
        ),
    };
  }
}

class _TaskStatsCard extends StatelessWidget {
  const _TaskStatsCard({
    required this.statType,
    required this.range,
    required this.supportBlockComputer,
    required this.tasks,
  });

  final TaskStatType statType;
  final DateRange? range;
  final SupportBlockComputer supportBlockComputer;
  final List<Task> tasks;

  String _labelForStat(TaskStatType type) {
    return switch (type) {
      TaskStatType.totalCount => 'Total tasks',
      TaskStatType.completedCount => 'Completed',
      TaskStatType.completionRate => 'Completion rate',
      TaskStatType.staleCount => 'Stale tasks',
      TaskStatType.overdueCount => 'Overdue',
      TaskStatType.avgDaysToComplete => 'Avg days to complete',
      TaskStatType.completedThisWeek => 'Done this week',
      TaskStatType.velocity => 'Velocity',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: supportBlockComputer.computeTaskStats(
        TaskStatsBlock(statType: statType, range: range),
        tasks,
      ),
      builder: (context, snapshot) {
        final label = _labelForStat(statType);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SupportCardContainer(
            title: label,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        if (snapshot.hasError) {
          return _SupportCardContainer(
            title: label,
            child: const Text('Failed to load'),
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return _SupportCardContainer(
            title: label,
            child: const Text('No data'),
          );
        }

        return _SupportCardContainer(
          title: label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.formattedValue ?? result.value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (result.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    result.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkflowProgressCard extends StatelessWidget {
  const _WorkflowProgressCard({required this.items});

  final List<WorkflowItem<Task>> items;

  @override
  Widget build(BuildContext context) {
    final progress = WorkflowProgress(
      total: items.length,
      completed: items
          .where((item) => item.status == WorkflowItemStatus.completed)
          .length,
      skipped: items
          .where((item) => item.status == WorkflowItemStatus.skipped)
          .length,
      pending: items
          .where((item) => item.status == WorkflowItemStatus.pending)
          .length,
    );

    return _SupportCardContainer(
      title: 'Workflow progress',
      child: WorkflowProgressBar(progress: progress),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.dimension,
    required this.statType,
    required this.range,
    required this.maxItems,
    required this.supportBlockComputer,
    required this.tasks,
  });

  final BreakdownDimension dimension;
  final TaskStatType statType;
  final DateRange? range;
  final int maxItems;
  final SupportBlockComputer supportBlockComputer;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: supportBlockComputer.computeBreakdown(
        BreakdownBlock(
          statType: statType,
          dimension: dimension,
          range: range,
          maxItems: maxItems,
        ),
        tasks,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SupportCardContainer(
            title: 'Breakdown by ${dimension.name}',
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        if (snapshot.hasError) {
          return _SupportCardContainer(
            title: 'Breakdown by ${dimension.name}',
            child: const Text('Failed to load'),
          );
        }

        final grouped = snapshot.data;
        if (grouped == null || grouped.isEmpty) {
          return _SupportCardContainer(
            title: 'Breakdown by ${dimension.name}',
            child: const Text('No data'),
          );
        }

        return _SupportCardContainer(
          title: 'Breakdown by ${dimension.name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: grouped.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(
                          entry.value.formattedValue ??
                              entry.value.value.toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _FilteredListCard extends StatelessWidget {
  const _FilteredListCard({
    required this.title,
    required this.maxItems,
    required this.block,
    required this.supportBlockComputer,
    required this.tasks,
  });

  final String title;
  final int maxItems;
  final FilteredListBlock block;
  final SupportBlockComputer supportBlockComputer;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: supportBlockComputer.computeFilteredTasks(
        block,
        tasks,
        now: DateTime.now(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SupportCardContainer(
            title: title,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        if (snapshot.hasError) {
          return _SupportCardContainer(
            title: title,
            child: const Text('Failed to load'),
          );
        }

        final filtered = snapshot.data ?? const <Task>[];
        final visible = filtered.take(maxItems).toList(growable: false);

        return _SupportCardContainer(
          title: title,
          child: filtered.isEmpty
              ? const Text('No matches')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final task in visible)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(task.name)),
                          ],
                        ),
                      ),
                    if (filtered.length > maxItems)
                      Text(
                        '+${filtered.length - maxItems} more',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _MoodCorrelationCard extends StatelessWidget {
  const _MoodCorrelationCard({
    required this.statType,
    required this.range,
    required this.supportBlockComputer,
    required this.tasks,
  });

  final TaskStatType statType;
  final DateRange? range;
  final SupportBlockComputer supportBlockComputer;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: supportBlockComputer.computeMoodCorrelation(
        MoodCorrelationBlock(statType: statType, range: range),
        tasks,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SupportCardContainer(
            title: 'Mood correlation',
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        }

        if (snapshot.hasError) {
          return _SupportCardContainer(
            title: 'Mood correlation',
            child: const Text('Failed to load'),
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return _SupportCardContainer(
            title: 'Mood correlation',
            child: const Text('No data'),
          );
        }

        return _SupportCardContainer(
          title: 'Mood correlation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correlating mood with ${statType.name}'),
              const SizedBox(height: 6),
              Text(
                'r=${result.coefficient.toStringAsFixed(2)} '
                '(n=${result.sampleSize ?? 0})',
              ),
              if (result.insight != null) ...[
                const SizedBox(height: 6),
                Text(
                  result.insight!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SupportCardContainer extends StatelessWidget {
  const _SupportCardContainer({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
