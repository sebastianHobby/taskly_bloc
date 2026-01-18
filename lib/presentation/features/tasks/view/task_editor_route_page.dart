import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_host_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';

/// Route-backed entry point for the task editor.
///
/// Per the core ED/RD contract, tasks are editor-only.
///
/// Canonical routes:
/// - Create: `/task/new`
/// - Edit: `/task/:id/edit`
///
/// When opened, this page launches the task editor modal and then returns to
/// the previous route when the modal is dismissed.
class TaskEditorRoutePage extends StatelessWidget {
  const TaskEditorRoutePage({
    required this.taskId,
    this.defaultProjectId,
    this.defaultValueIds,
    super.key,
  });

  final String? taskId;
  final String? defaultProjectId;
  final List<String>? defaultValueIds;

  @override
  Widget build(BuildContext context) {
    return EditorHostPage(
      openModal: (context) => EditorLauncher.fromGetIt().openTaskEditor(
        context,
        taskId: taskId,
        defaultProjectId: defaultProjectId,
        defaultValueIds: defaultValueIds,
        showDragHandle: true,
      ),
      fullPageBuilder: (_) => _TaskEditorFullPage(
        taskId: taskId,
        defaultProjectId: defaultProjectId,
        defaultValueIds: defaultValueIds,
      ),
    );
  }
}

class _TaskEditorFullPage extends StatelessWidget {
  const _TaskEditorFullPage({
    required this.taskId,
    required this.defaultProjectId,
    required this.defaultValueIds,
  });

  final String? taskId;
  final String? defaultProjectId;
  final List<String>? defaultValueIds;

  @override
  Widget build(BuildContext context) {
    final taskRepository = getIt<TaskRepositoryContract>();
    final projectRepository = getIt<ProjectRepositoryContract>();
    final valueRepository = getIt<ValueRepositoryContract>();

    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (context) => TaskDetailBloc(
            taskId: taskId,
            taskRepository: taskRepository,
            projectRepository: projectRepository,
            valueRepository: valueRepository,
            errorReporter: context.read<AppErrorReporter>(),
          ),
          child: TaskDetailSheet(
            defaultProjectId: defaultProjectId,
            defaultValueIds: defaultValueIds,
          ),
        ),
      ),
    );
  }
}
