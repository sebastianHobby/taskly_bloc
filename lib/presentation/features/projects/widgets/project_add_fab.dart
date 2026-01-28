import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';

/// A FAB that opens a project creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddTaskFab` and `AddValueFab`.
class AddProjectFab extends StatelessWidget {
  const AddProjectFab({
    super.key,
  });

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: fabContext.l10n.createProjectTooltip,
      onPressed: () async {
        final launcher = fabContext.read<EditorLauncher>();
        await launcher.openProjectEditor(fabContext);
      },
      heroTag: 'create_project_fab',
      child: const Icon(Icons.add),
    );
  }
}
