import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// A compact list of task previews for problem context.
///
/// Shows a limited number of tasks with their names and optional
/// deadline indicators. Used within problem cards to show affected tasks.
class TaskPreviewList extends StatelessWidget {
  /// Creates a task preview list.
  const TaskPreviewList({
    required this.tasks,
    this.maxItems = 3,
    this.onTaskTap,
    this.showDeadline = true,
    super.key,
  });

  /// The tasks to display.
  final List<Task> tasks;

  /// Maximum number of tasks to show before truncating.
  final int maxItems;

  /// Callback when a task is tapped.
  final void Function(Task task)? onTaskTap;

  /// Whether to show deadline indicators.
  final bool showDeadline;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTasks = tasks.take(maxItems).toList();
    final remaining = tasks.length - maxItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayTasks.map(
          (task) => _TaskPreviewItem(
            task: task,
            onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
            showDeadline: showDeadline,
          ),
        ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+$remaining more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskPreviewItem extends StatelessWidget {
  const _TaskPreviewItem({
    required this.task,
    this.onTap,
    this.showDeadline = true,
  });

  final Task task;
  final VoidCallback? onTap;
  final bool showDeadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              task.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 16,
              color: task.completed
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.completed
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showDeadline && task.deadlineDate != null) ...[
              const SizedBox(width: 8),
              _DeadlineIndicator(deadline: task.deadlineDate!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeadlineIndicator extends StatelessWidget {
  const _DeadlineIndicator({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    final isOverdue = deadlineDate.isBefore(today);
    final isToday = deadlineDate.isAtSameMomentAs(today);
    final isTomorrow = deadlineDate.isAtSameMomentAs(
      today.add(const Duration(days: 1)),
    );

    final (label, color) = switch (true) {
      _ when isOverdue => ('Overdue', colorScheme.error),
      _ when isToday => ('Today', colorScheme.primary),
      _ when isTomorrow => ('Tomorrow', colorScheme.tertiary),
      _ => (_formatDate(deadline), colorScheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
