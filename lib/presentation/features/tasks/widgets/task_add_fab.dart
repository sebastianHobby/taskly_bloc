import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';

/// A FAB that opens a task creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddProjectFab` and `AddLabelFab`.
class AddTaskFab extends StatelessWidget {
  const AddTaskFab({
    required this.taskRepository,
    required this.projectRepository,
    required this.valueRepository,
    this.defaultProjectId,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;

  /// Optional project ID to pre-select in the task form.
  final String? defaultProjectId;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: fabContext.l10n.createTaskTooltip,
      onPressed: () async {
        final launcher = EditorLauncher(
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          valueRepository: valueRepository,
        );
        await launcher.openTaskEditor(
          fabContext,
          defaultProjectId: defaultProjectId,
        );
      },
      heroTag: 'create_task_fab',
      child: const Icon(Icons.add),
    );
  }
}
