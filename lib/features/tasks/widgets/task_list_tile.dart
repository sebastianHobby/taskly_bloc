import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/features/tasks/bloc/tasks_bloc.dart';
import 'package:taskly_bloc/features/tasks/models/task_models.dart';

class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.task,
    super.key,
  });

  final TaskDto task;
  //  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final captionColor = theme.textTheme.bodySmall?.color;
    bool completed = task.completed;
    return ListTile(
      //    onTap: onTap,
      title: Text(
        task.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        task.description!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Checkbox(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        value: completed,
        onChanged: (bool? newValue) {
          completed = newValue ?? false;
          final TaskUpdateRequest updateRequest = TaskUpdateRequest(
            id: task.id,
            name: task.name,
            completed: completed,
            description: task.description,
          );
          // Create event to update task with new completed status

          context.read<TasksBloc>().add(
            TasksEvent.updateTask(updateRequest: updateRequest),
          );
        },
      ),
      //   trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
