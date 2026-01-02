import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/allocation_bloc.dart';

/// Widget for displaying a group of tasks allocated to a value
class AllocatedGroupWidget extends StatelessWidget {
  const AllocatedGroupWidget({
    required this.group,
    required this.onPin,
    required this.onTaskTap,
    required this.onToggleComplete,
    super.key,
  });

  final AllocationGroup group;
  final void Function(String taskId) onPin;
  final void Function(String taskId) onTaskTap;
  final void Function(String taskId) onToggleComplete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.valueName.toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: group.tasks.length / group.quota,
                        backgroundColor: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${group.tasks.length} of ${group.quota}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final allocatedTask = group.tasks[index];
              return _AllocatedTaskTile(
                allocatedTask: allocatedTask,
                onPin: () => onPin(allocatedTask.task.id),
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

class _AllocatedTaskTile extends StatelessWidget {
  const _AllocatedTaskTile({
    required this.allocatedTask,
    required this.onPin,
    required this.onTaskTap,
    required this.onToggleComplete,
  });

  final AllocatedTask allocatedTask;
  final VoidCallback onPin;
  final VoidCallback onTaskTap;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final task = allocatedTask.task;

    // Get value label names for "Also:" indicator (excluding the qualifying value)
    final valueLabels = task.labels
        .where((l) => l.type == LabelType.value)
        .toList();
    final qualifyingLabel = valueLabels.firstWhere(
      (l) => l.id == allocatedTask.qualifyingValueId,
      orElse: () => valueLabels.first,
    );
    final otherValueLabels = valueLabels
        .where((l) => l.id != qualifyingLabel.id)
        .toList();

    return ListTile(
      leading: Semantics(
        label: task.completed
            ? 'Mark "${task.name}" as incomplete'
            : 'Mark "${task.name}" as complete',
        child: Checkbox(
          value: task.completed,
          onChanged: (_) {
            HapticFeedback.lightImpact();
            onToggleComplete();
          },
        ),
      ),
      title: Text(
        task.name,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.deadlineDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDeadline(task.deadlineDate!),
                ),
              ],
            ),
          ],
          if (otherValueLabels.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Also: ${otherValueLabels.map((l) => l.name).join(", ")}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allocatedTask.allocationScore > 0)
            Chip(
              label: Text(
                allocatedTask.allocationScore.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            icon: const Icon(Icons.push_pin_outlined),
            tooltip: 'Pin to top',
            onPressed: onPin,
          ),
        ],
      ),
      onTap: onTaskTap,
    );
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
