import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_host_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

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
      openModal: (context) => context.read<EditorLauncher>().openTaskEditor(
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
    final taskRepository = context.read<TaskRepositoryContract>();
    final projectRepository = context.read<ProjectRepositoryContract>();
    final valueRepository = context.read<ValueRepositoryContract>();
    final taskWriteService = context.read<TaskWriteService>();
    final taskMyDayWriteService = context.read<TaskMyDayWriteService>();
    final demoModeService = context.read<DemoModeService>();
    final demoDataProvider = context.read<DemoDataProvider>();

    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (context) => TaskDetailBloc(
            taskId: taskId,
            taskRepository: taskRepository,
            projectRepository: projectRepository,
            valueRepository: valueRepository,
            taskWriteService: taskWriteService,
            taskMyDayWriteService: taskMyDayWriteService,
            errorReporter: context.read<AppErrorReporter>(),
            demoModeService: demoModeService,
            demoDataProvider: demoDataProvider,
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
