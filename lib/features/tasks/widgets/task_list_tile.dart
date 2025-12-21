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

  Color _colorFromHexOrFallback(String? hex) {
    final normalized = (hex ?? '').replaceAll('#', '');
    if (normalized.length != 6) return Colors.black;
    final value = int.tryParse('FF$normalized', radix: 16);
    if (value == null) return Colors.black;
    return Color(value);
  }

  String _formatDate(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatShortDate(value);
  }

  Widget? _buildSubtitle(BuildContext context) {
    final description = task.description;
    final hasDescription = description != null && description.isNotEmpty;

    final labels = task.labels;
    final hasLabels = labels.isNotEmpty;

    final startDate = task.startDate;
    final deadlineDate = task.deadlineDate;
    final hasDates = startDate != null || deadlineDate != null;

    if (!hasDescription && !hasLabels && !hasDates) return null;

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
        if (hasLabels) ...[
          if (hasDescription) const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final label in labels)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 14,
                      color: _colorFromHexOrFallback(label.color),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label.name,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (hasDates) ...[
          if (hasDescription || hasLabels) const SizedBox(height: 6),
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
