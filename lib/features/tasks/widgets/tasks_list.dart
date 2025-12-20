import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';

class TasksListView extends StatelessWidget {
  const TasksListView({
    required this.tasks,
    required this.onTap,
    super.key,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onTap;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskOverviewBloc>();

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListTile(
          task: task,
          onCheckboxChanged: (task, isCompleted) {
            if (isCompleted != null) {
              bloc.add(
                TaskOverviewEvent.toggleTaskCompletion(
                  task: task,
                ),
              );
            }
          },
          onTap: onTap,
        );
      },
    );
  }
}
