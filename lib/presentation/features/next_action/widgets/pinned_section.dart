import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';

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
              return TaskListTile(
                task: allocatedTask.task,
                onTap: (task) => onTaskTap(task.id),
                onCheckboxChanged: (task, _) => onToggleComplete(task.id),
                onNextActionRemoved: (task) => onUnpin(task.id),
                showNextActionIndicator: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
