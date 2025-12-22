import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';

class AddProjectFab extends StatelessWidget {
  const AddProjectFab({
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: fabContext.l10n.createProjectTooltip,
      onPressed: () async {
        await showDetailModal<void>(
          context: fabContext,
          childBuilder: (modalSheetContext) => SafeArea(
            top: false,
            child: ProjectEditSheetPage(
              projectRepository: projectRepository,
              labelRepository: labelRepository,
              onSuccess: (message) {
                Navigator.of(modalSheetContext).pop();
                ScaffoldMessenger.of(fabContext).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
              onError: (errorMessage) {
                ScaffoldMessenger.of(fabContext).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
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
