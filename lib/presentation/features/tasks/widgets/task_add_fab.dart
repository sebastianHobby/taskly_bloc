import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';

/// A FAB that opens a task creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddProjectFab` and `AddValueFab`.
class AddTaskFab extends StatelessWidget {
  const AddTaskFab({
    required this.taskRepository,
    required this.projectRepository,
    required this.valueRepository,
    this.defaultProjectId,
    this.defaultValueIds,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;

  /// Optional project ID to pre-select in the task form.
  final String? defaultProjectId;

  /// Optional value IDs to pre-select in the task form.
  ///
  /// Useful for creating a task "aligned" to a Value detail screen.
  final List<String>? defaultValueIds;

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
          defaultValueIds: defaultValueIds,
        );
      },
      heroTag: 'create_task_fab',
      child: const Icon(Icons.add),
    );
  }
}
