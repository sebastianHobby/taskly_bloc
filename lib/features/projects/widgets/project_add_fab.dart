import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/view/project_detail_view.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';

class AddProjectFab extends StatelessWidget {
  const AddProjectFab({
    required this.projectRepository,
    super.key,
  });

  final ProjectRepository projectRepository;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: 'Create project',
      onPressed: () async {
        await showDetailModal<void>(
          context: fabContext,
          childBuilder: (modalSheetContext) => SafeArea(
            top: false,
            child: ProjectDetailSheetPage(
              projectRepository: projectRepository,
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
        );
      },
      heroTag: 'create_project_fab',
      child: const Icon(Icons.add),
    );
  }
}
