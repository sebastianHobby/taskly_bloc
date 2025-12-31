import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';

/// Section displaying pinned/next action tasks
class PinnedSection extends StatelessWidget {
  const PinnedSection({
    required this.pinnedTasks,
    required this.onUnpin,
    required this.onTaskTap,
    required this.onToggleComplete,
    super.key,
  });

  final List<AllocatedTask> pinnedTasks;
  final void Function(String taskId) onUnpin;
  final void Function(String taskId) onTaskTap;
  final void Function(String taskId) onToggleComplete;

  @override
  Widget build(BuildContext context) {
    if (pinnedTasks.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.push_pin,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.nextActionsTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pinnedTasks.length}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pinnedTasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final allocatedTask = pinnedTasks[index];
              return _PinnedTaskTile(
                allocatedTask: allocatedTask,
                onUnpin: () => onUnpin(allocatedTask.task.id),
                onTaskTap: () => onTaskTap(allocatedTask.task.id),
                onToggleComplete: () => onToggleComplete(allocatedTask.task.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PinnedTaskTile extends StatelessWidget {
  const _PinnedTaskTile({
    required this.allocatedTask,
    required this.onUnpin,
    required this.onTaskTap,
    required this.onToggleComplete,
  });

  final AllocatedTask allocatedTask;
  final VoidCallback onUnpin;
  final VoidCallback onTaskTap;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final task = allocatedTask.task;

    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) => onToggleComplete(),
      ),
      title: Text(
        task.name,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: task.deadlineDate != null
          ? Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: _getDeadlineColor(
                    task.deadlineDate!,
                    context,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDeadline(task.deadlineDate!),
                  style: TextStyle(
                    color: _getDeadlineColor(
                      task.deadlineDate!,
                      context,
                    ),
                  ),
                ),
              ],
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.push_pin),
        tooltip: 'Remove Next Action',
        onPressed: onUnpin,
      ),
      onTap: onTaskTap,
    );
  }

  Color _getDeadlineColor(DateTime deadline, BuildContext context) {
    final daysUntil = deadline.difference(DateTime.now()).inDays;
    if (daysUntil < 0) {
      return Colors.red;
    } else if (daysUntil <= 3) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.inDays < 0) {
      return 'Overdue';
    } else if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays <= 7) {
      return 'in ${diff.inDays} days';
    } else {
      return '${deadline.month}/${deadline.day}';
    }
  }
}
