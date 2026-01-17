import 'package:flutter/material.dart';
import 'package:taskly_domain/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';

/// A FAB that opens a value creation modal sheet.
///
/// Encapsulates all modal handling internally, consistent with
/// `AddTaskFab` and `AddProjectFab`.
class AddValueFab extends StatelessWidget {
  const AddValueFab({
    required this.valueRepository,
    required this.tooltip,
    required this.heroTag,
    super.key,
  });

  final ValueRepositoryContract valueRepository;
  final String tooltip;
  final String heroTag;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: () async {
        final launcher = EditorLauncher(
          projectRepository: getIt<ProjectRepositoryContract>(),
          valueRepository: valueRepository,
        );
        await launcher.openValueEditor(fabContext);
      },
      heroTag: heroTag,
      child: const Icon(Icons.add),
    );
  }
}
