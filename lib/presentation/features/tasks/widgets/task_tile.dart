import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/theme/app_colors.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    super.key,
    this.onToggle,
    this.onTap,
    this.isCompact = false,
  });
  final Task task;
  final void Function(bool?)? onToggle;
  final VoidCallback? onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.MMMd();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TasklyCard(
      onTap: onTap,
      padding: isCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      child: Row(
        children: [
          // Custom Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: task.completed,
              onChanged: onToggle,
              activeColor: colorScheme.primary,
              checkColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(
                color: colorScheme.outline,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.completed
                        ? colorScheme.onSurface.withOpacity(0.5)
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (task.project != null) ...[
                        Icon(
                          Icons.folder_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.project!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (task.deadlineDate != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: task.deadlineDate!.isBefore(DateTime.now())
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(task.deadlineDate!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: task.deadlineDate!.isBefore(DateTime.now())
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (task.priority != null) ...[
                        Icon(
                          Icons.flag,
                          size: 14,
                          color: _getPriorityColor(context, task.priority!),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'P${task.priority}',
                          style: TextStyle(
                            color: _getPriorityColor(context, task.priority!),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (task.labels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: task.labels
                          .map(
                            (label) => TasklyBadge(
                              label: label.name,
                              color: colorScheme.primary,
                              isOutlined: true,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, int priority) {
    switch (priority) {
      case 1:
        return Theme.of(context).colorScheme.error;
      case 2:
        return Colors.orangeAccent; // Keep distinct priority colors
      case 3:
        return Colors.blueAccent;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
