import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_host_page.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';

/// Route-backed entry point for the project editor.
///
/// Routes:
/// - Create: `/project/new`
/// - Edit: `/project/:id/edit`
///
/// This page opens the project editor modal and then returns to the previous
/// route when the modal is dismissed.
class ProjectEditorRoutePage extends StatelessWidget {
  const ProjectEditorRoutePage({
    required this.projectId,
    super.key,
  });

  final String? projectId;

  @override
  Widget build(BuildContext context) {
    return EditorHostPage(
      openModal: (context) => EditorLauncher.fromGetIt().openProjectEditor(
        context,
        projectId: projectId,
        showDragHandle: true,
      ),
      fullPageBuilder: (_) => _ProjectEditorFullPage(projectId: projectId),
    );
  }
}

class _ProjectEditorFullPage extends StatelessWidget {
  const _ProjectEditorFullPage({required this.projectId});

  final String? projectId;

  @override
  Widget build(BuildContext context) {
    final projectRepository = getIt<ProjectRepositoryContract>();
    final valueRepository = getIt<ValueRepositoryContract>();

    return Scaffold(
      body: SafeArea(
        child: ProjectEditSheetPage(
          projectId: projectId,
          projectRepository: projectRepository,
          valueRepository: valueRepository,
        ),
      ),
    );
  }
}
