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

  @override
  Widget build(BuildContext context) {
    final description = task.description;
    final hasDescription = description != null && description.isNotEmpty;

    return ListTile(
      key: Key('task-${task.id}'),
      leading: Checkbox(
        value: task.completed,
        onChanged: (value) => onCheckboxChanged(task, value),
      ),
      title: Text(task.name),
      subtitle: hasDescription ? Text(description) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onTap(task),
    );
  }
}
