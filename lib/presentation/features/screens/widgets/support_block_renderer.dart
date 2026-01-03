import 'package:flutter/material.dart';
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

    final sortedBlocks = supportBlockComputer.sortByOrder(blocks);

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
            children: sortedBlocks
                .map(
                  (block) => SupportBlockCard(
                    block: block,
                    items: items,
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
    required this.supportBlockComputer,
    super.key,
  });

  final SupportBlock block;
  final List<WorkflowItem<Task>> items;
  final SupportBlockComputer supportBlockComputer;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      WorkflowProgressBlock() => _WorkflowProgressCard(items: items),
      QuickActionsBlock(:final actions) => _QuickActionsCard(actions: actions),
      ContextSummaryBlock(
        :final title,
        :final showDescription,
        :final showMetadata,
      ) =>
        _ContextSummaryCard(
          title: title,
          showDescription: showDescription,
          showMetadata: showMetadata,
        ),
      RelatedEntitiesBlock(:final entityTypes, :final maxItems) =>
        _RelatedEntitiesCard(entityTypes: entityTypes, maxItems: maxItems),
      StatsBlock(:final stats) => _StatsCard(
        stats: stats,
        supportBlockComputer: supportBlockComputer,
      ),
      ProblemSummaryBlock(
        :final title,
        :final showCount,
        :final showList,
        :final maxListItems,
      ) =>
        _ProblemSummaryCard(
          title: title ?? 'Issues',
          showCount: showCount,
          showList: showList,
          maxListItems: maxListItems,
          supportBlockComputer: supportBlockComputer,
          block: block as ProblemSummaryBlock,
        ),
      EmptyStateBlock(:final message, :final icon, :final actionLabel) =>
        _EmptyStateCard(
          message: message,
          icon: icon,
          actionLabel: actionLabel,
        ),
      EntityHeaderBlock() =>
        // EntityHeader is rendered separately in detail pages
        // as it needs entity data, not just configuration
        const SizedBox.shrink(),
    };
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

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.actions,
    // ignore: unused_element_parameter
    this.onActionTap,
  });

  final List<QuickAction> actions;

  /// Called when a quick action is tapped. Extension point for action handling.
  final void Function(QuickAction action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    return _SupportCardContainer(
      title: 'Quick Actions',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return ActionChip(
            label: Text(action.label),
            onPressed: onActionTap != null ? () => onActionTap!(action) : null,
          );
        }).toList(),
      ),
    );
  }
}

class _ContextSummaryCard extends StatelessWidget {
  const _ContextSummaryCard({
    required this.title,
    required this.showDescription,
    required this.showMetadata,
  });

  final String? title;
  final bool showDescription;
  final bool showMetadata;

  @override
  Widget build(BuildContext context) {
    return _SupportCardContainer(
      title: title ?? 'Context',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDescription)
            Text(
              'Context information will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (showMetadata)
            Text(
              'Metadata will appear here',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _RelatedEntitiesCard extends StatelessWidget {
  const _RelatedEntitiesCard({
    required this.entityTypes,
    required this.maxItems,
  });

  final List<String> entityTypes;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    return _SupportCardContainer(
      title: 'Related Items',
      child: Text(
        'Related ${entityTypes.join(", ")} will appear here',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.stats,
    required this.supportBlockComputer,
  });

  final List<StatConfig> stats;
  final SupportBlockComputer supportBlockComputer;

  @override
  Widget build(BuildContext context) {
    return _SupportCardContainer(
      title: 'Statistics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stats.map((stat) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(stat.label),
                const Text('--'), // Placeholder for computed value
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProblemSummaryCard extends StatelessWidget {
  const _ProblemSummaryCard({
    required this.title,
    required this.showCount,
    required this.showList,
    required this.maxListItems,
    required this.supportBlockComputer,
    required this.block,
  });

  final String title;
  final bool showCount;
  final bool showList;
  final int maxListItems;
  final SupportBlockComputer supportBlockComputer;
  final ProblemSummaryBlock block;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: supportBlockComputer.computeProblemCount(block),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return _SupportCardContainer(
          title: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCount)
                Row(
                  children: [
                    Icon(
                      count > 0 ? Icons.warning_amber : Icons.check_circle,
                      color: count > 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      count > 0
                          ? '$count issue${count > 1 ? 's' : ''}'
                          : 'No issues',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              if (showList && count > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Problem details will appear here',
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

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.message,
    required this.icon,
    required this.actionLabel,
    // ignore: unused_element_parameter
    this.onAction,
  });

  final String message;
  final String? icon;
  final String? actionLabel;

  /// Called when the empty state action button is tapped. Extension point.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _SupportCardContainer(
      title: '',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
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
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
