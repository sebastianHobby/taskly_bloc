import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/features/tasks/tasks.dart.dart';

class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.taskDto,
    required this.onTap,
    super.key,
  });

  final TaskDto taskDto;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final captionColor = theme.textTheme.bodySmall?.color;
    final bool completed = taskDto.completed;
    return ListTile(
      onTap: onTap, // invoke the passed-in method when tapped
      title: Text(
        taskDto.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        taskDto.description!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Checkbox(
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        value: completed,
        onChanged: (bool? newValue) {
          context.read<TaskListBloc>().add(
            TaskListEvent.toggleTaskCompletion(taskDto: taskDto),
          );
        },
      ),
    );
  }
}
