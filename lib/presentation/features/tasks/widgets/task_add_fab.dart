import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';

/// A FAB that opens a task creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddProjectFab` and `AddValueFab`.
class AddTaskFab extends StatelessWidget {
  const AddTaskFab({
    this.defaultProjectId,
    this.defaultValueIds,
    super.key,
  });

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
        final launcher = fabContext.read<EditorLauncher>();
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
