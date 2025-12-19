import 'package:flutter/material.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';

class AddTaskFab extends StatelessWidget {
  const AddTaskFab({
    required this.context,
    super.key,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: 'Create task',
      onPressed: () async {
        late PersistentBottomSheetController controller;
        controller = Scaffold.of(fabContext).showBottomSheet(
          (ctx) => Material(
            color: Theme.of(ctx).colorScheme.surface,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: TaskDetailSheetPage(
                onSuccess: (message) {
                  controller.close();
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
          ),
        );
      },
      heroTag: 'create_task_fab',
      child: const Icon(Icons.add),
    );
  }
}
