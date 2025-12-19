import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';

ListView TasksList(List<TaskTableData> tasks, BuildContext context) {
  return ListView.builder(
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      return TaskListTile(
        task: task,
        onCheckboxChanged: (task, _) {
          context.read<TaskOverviewBloc>().add(
            TaskOverviewEvent.toggleTaskCompletion(
              taskData: task,
            ),
          );
        },
        onTap: (task) async {
          late PersistentBottomSheetController controller;
          controller = Scaffold.of(context).showBottomSheet(
            (ctx) => Material(
              color: Theme.of(ctx).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: TaskDetailSheetPage(
                  taskId: task.id,
                  onSuccess: (message) {
                    controller.close();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  onError: (errorMessage) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $errorMessage')),
                    );
                  },
                ),
              ),
            ),
            elevation: 8,
          );
        },
      );
    },
  );
}
