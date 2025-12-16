import 'package:flutter/material.dart';

import 'package:taskly_bloc/data/drift/drift_database.dart';

/// A single list tile representing a TaskTableData.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.task,
    required this.onCheckboxChanged,
    required this.onTap,
    super.key,
  });

  final TaskTableData task;
  final void Function(TaskTableData, bool?) onCheckboxChanged;
  final void Function(TaskTableData) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(task),
      title: Text(
        task.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (task.description == null || task.description!.isEmpty)
          ? null
          : Text(
              task.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      leading: Checkbox(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        value: task.completed,
        onChanged: (value) => onCheckboxChanged(task, value),
      ),
    );
  }
}
