import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';

class TasksListView extends StatelessWidget {
  const TasksListView({
    required this.tasks,
    required this.taskRepository,
    super.key,
  });

  final List<TaskTableData> tasks;
  final TaskRepository taskRepository;

  @override
  Widget build(BuildContext context) {
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
            await showDetailModal<void>(
              context: context,
              childBuilder: (modalSheetContext) => SafeArea(
                top: false,
                child: TaskDetailSheetPage(
                  taskId: task.id,
                  taskRepository: taskRepository,
                  onSuccess: (message) {
                    Navigator.of(modalSheetContext).pop();

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
              modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
            );
          },
        );
      },
    );
  }
}
