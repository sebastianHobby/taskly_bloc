import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/shared/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/shared/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';

class TasksListView extends StatelessWidget {
  const TasksListView({
    required this.tasks,
    required this.onTap,
    this.shrinkWrap = false,
    this.physics,
    this.enableSwipeToDelete = true,
    super.key,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onTap;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool enableSwipeToDelete;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskOverviewBloc>();

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return SwipeToDelete(
          itemKey: ValueKey(task.id),
          enabled: enableSwipeToDelete,
          confirmDismiss: () => showDeleteConfirmationDialog(
            context: context,
            title: 'Delete Task',
            itemName: task.name,
            description: 'This action cannot be undone.',
          ),
          onDismissed: () {
            bloc.add(TaskOverviewEvent.deleteTask(task: task));
            showDeleteSnackBar(
              context: context,
              message: 'Task deleted',
            );
          },
          child: TaskListTile(
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
          ),
        );
      },
    );
  }
}
