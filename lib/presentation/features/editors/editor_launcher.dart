import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_view.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';

/// Centralized entry point for launching create/edit entity forms.
///
/// This standardizes:
/// - Adaptive modal presentation (sheet on compact, dialog on larger screens)
/// - How editor dependencies are constructed
/// - Optional refresh callbacks
///
/// Note: Entity *detail pages* remain route-based; this launcher is for
/// create/edit forms.
class EditorLauncher {
  const EditorLauncher({
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    TaskRepositoryContract? taskRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository;

  factory EditorLauncher.fromGetIt() {
    return EditorLauncher(
      taskRepository: getIt<TaskRepositoryContract>(),
      projectRepository: getIt<ProjectRepositoryContract>(),
      valueRepository: getIt<ValueRepositoryContract>(),
    );
  }

  final TaskRepositoryContract? _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;

  Future<void> openTaskEditor(
    BuildContext context, {
    String? taskId,
    String? defaultProjectId,
    bool showDragHandle = false,
  }) {
    final taskRepository = _taskRepository;
    if (taskRepository == null) {
      throw StateError(
        'EditorLauncher.openTaskEditor requires a TaskRepositoryContract.',
      );
    }

    return showDetailModal<void>(
      context: context,
      showDragHandle: showDragHandle,
      childBuilder: (modalContext) {
        return BlocProvider(
          create: (_) => TaskDetailBloc(
            taskId: taskId,
            taskRepository: taskRepository,
            projectRepository: _projectRepository,
            valueRepository: _valueRepository,
          ),
          child: TaskDetailSheet(defaultProjectId: defaultProjectId),
        );
      },
    );
  }

  Future<void> openProjectEditor(
    BuildContext context, {
    String? projectId,
    void Function(String projectId)? onSaved,
    bool showDragHandle = false,
  }) {
    return showDetailModal<void>(
      context: context,
      showDragHandle: showDragHandle,
      childBuilder: (modalContext) {
        return ProjectEditSheetPage(
          projectId: projectId,
          projectRepository: _projectRepository,
          valueRepository: _valueRepository,
          onSaved: onSaved,
        );
      },
    );
  }

  Future<void> openValueEditor(
    BuildContext context, {
    String? valueId,
    void Function(String valueId)? onSaved,
    bool showDragHandle = false,
  }) {
    return showDetailModal<void>(
      context: context,
      showDragHandle: showDragHandle,
      childBuilder: (modalContext) {
        return ValueDetailSheetPage(
          valueId: valueId,
          valueRepository: _valueRepository,
          onSaved: onSaved,
        );
      },
    );
  }
}
