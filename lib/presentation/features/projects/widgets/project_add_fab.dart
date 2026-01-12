import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';

/// A FAB that opens a project creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddTaskFab` and `AddLabelFab`.
class AddProjectFab extends StatelessWidget {
  const AddProjectFab({
    required this.projectRepository,
    required this.valueRepository,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: fabContext.l10n.createProjectTooltip,
      onPressed: () async {
        final launcher = EditorLauncher(
          projectRepository: projectRepository,
          valueRepository: valueRepository,
        );
        await launcher.openProjectEditor(fabContext);
      },
      heroTag: 'create_project_fab',
      child: const Icon(Icons.add),
    );
  }
}
