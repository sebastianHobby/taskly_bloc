import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/domain/core/editing/value/value_draft.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_view.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
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
    List<String>? defaultValueIds,
    bool openToValues = false,
    bool openToProjectPicker = false,
    bool? showDragHandle,
  }) {
    final taskRepository = _taskRepository;
    if (taskRepository == null) {
      throw StateError(
        'EditorLauncher.openTaskEditor requires a TaskRepositoryContract.',
      );
    }

    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return BlocProvider(
          create: (_) => TaskDetailBloc(
            taskId: taskId,
            taskRepository: taskRepository,
            projectRepository: _projectRepository,
            valueRepository: _valueRepository,
          ),
          child: TaskDetailSheet(
            defaultProjectId: defaultProjectId,
            defaultValueIds: defaultValueIds,
            openToValues: openToValues,
            openToProjectPicker: openToProjectPicker,
          ),
        );
      },
    );
  }

  Future<void> openProjectEditor(
    BuildContext context, {
    String? projectId,
    void Function(String projectId)? onSaved,
    bool openToValues = false,
    bool? showDragHandle,
  }) {
    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return ProjectEditSheetPage(
          projectId: projectId,
          projectRepository: _projectRepository,
          valueRepository: _valueRepository,
          onSaved: onSaved,
          openToValues: openToValues,
        );
      },
    );
  }

  Future<void> openValueEditor(
    BuildContext context, {
    String? valueId,
    ValueDraft? initialDraft,
    void Function(String valueId)? onSaved,
    bool? showDragHandle,
  }) {
    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return ValueDetailSheetPage(
          valueId: valueId,
          valueRepository: _valueRepository,
          initialDraft: valueId == null ? initialDraft : null,
          onSaved: onSaved,
        );
      },
    );
  }
}
