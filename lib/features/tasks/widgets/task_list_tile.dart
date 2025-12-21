import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A single list tile representing a task.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.task,
    required this.onCheckboxChanged,
    required this.onTap,
    super.key,
  });

  final Task task;
  final void Function(Task, bool?) onCheckboxChanged;
  final void Function(Task) onTap;

  String _formatDate(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatShortDate(value);
  }

  Widget? _buildSubtitle(BuildContext context) {
    final description = task.description;
    final hasDescription = description != null && description.isNotEmpty;

    final startDate = task.startDate;
    final deadlineDate = task.deadlineDate;
    final hasDates = startDate != null || deadlineDate != null;

    if (!hasDescription && !hasDates) return null;

    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDescription)
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (hasDates) ...[
          if (hasDescription) const SizedBox(height: 6),
          if (startDate != null)
            Row(
              children: [
                const Icon(Icons.play_arrow_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(context, startDate),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (deadlineDate != null)
            Padding(
              padding: EdgeInsets.only(top: startDate != null ? 4 : 0),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDate(context, deadlineDate),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('task-${task.id}'),
      leading: Checkbox(
        value: task.completed,
        onChanged: (value) => onCheckboxChanged(task, value),
      ),
      title: Text(task.name),
      subtitle: _buildSubtitle(context),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onTap(task),
    );
  }
}
