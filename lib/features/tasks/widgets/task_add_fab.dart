import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';

class AddTaskFab extends StatelessWidget {
  const AddTaskFab({
    required this.taskRepository,
    super.key,
  });

  final TaskRepository taskRepository;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: 'Create task',
      onPressed: () async {
        await showDetailModal<void>(
          context: fabContext,
          childBuilder: (modalSheetContext) => SafeArea(
            top: false,
            child: TaskDetailSheetPage(
              taskRepository: taskRepository,
              onSuccess: (message) {
                Navigator.of(modalSheetContext).pop();
                ScaffoldMessenger.of(fabContext).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              onError: (errorMessage) {
                ScaffoldMessenger.of(fabContext).showSnackBar(
                  SnackBar(
                    content: Text('Error: $errorMessage'),
                  ),
                );
              },
            ),
          ),
          modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
        );
      },
      heroTag: 'create_task_fab',
      child: const Icon(Icons.add),
    );
  }
}
