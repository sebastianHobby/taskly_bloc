import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A FAB that opens a value creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddTaskFab` and `AddProjectFab`.
class AddValueFab extends StatelessWidget {
  const AddValueFab({
    required this.tooltip,
    required this.heroTag,
    super.key,
  });

  final String tooltip;
  final String heroTag;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: () async {
        final launcher = fabContext.read<EditorLauncher>();
        await launcher.openValueEditor(fabContext);
      },
      heroTag: heroTag,
      child: const Icon(Icons.add),
    );
  }
}
