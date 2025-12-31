import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';

/// A FAB that opens a project creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddTaskFab` and `AddLabelFab`.
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
          childBuilder: (modalSheetContext) => ProjectEditSheetPage(
            projectRepository: projectRepository,
            labelRepository: labelRepository,
          ),
        );
      },
      heroTag: 'create_project_fab',
      child: const Icon(Icons.add),
    );
  }
}
