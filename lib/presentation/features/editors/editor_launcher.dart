import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routine_detail_view.dart';
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
    RoutineRepositoryContract? routineRepository,
    TaskWriteService? taskWriteService,
    ProjectWriteService? projectWriteService,
    ValueWriteService? valueWriteService,
    RoutineWriteService? routineWriteService,
  }) : _taskRepository = taskRepository,
       _routineRepository = routineRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _taskWriteService = taskWriteService,
       _projectWriteService = projectWriteService,
       _valueWriteService = valueWriteService,
       _routineWriteService = routineWriteService;

  final TaskRepositoryContract? _taskRepository;
  final RoutineRepositoryContract? _routineRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final TaskWriteService? _taskWriteService;
  final ProjectWriteService? _projectWriteService;
  final ValueWriteService? _valueWriteService;
  final RoutineWriteService? _routineWriteService;

  Future<void> openTaskEditor(
    BuildContext context, {
    String? taskId,
    String? defaultProjectId,
    List<String>? defaultValueIds,
    DateTime? defaultStartDate,
    DateTime? defaultDeadlineDate,
    bool openToValues = false,
    bool openToProjectPicker = false,
    bool? showDragHandle,
  }) {
    final taskRepository = _taskRepository;
    final taskWriteService = _taskWriteService;
    if (taskRepository == null || taskWriteService == null) {
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
          create: (context) => TaskDetailBloc(
            taskId: taskId,
            taskRepository: taskRepository,
            projectRepository: _projectRepository,
            valueRepository: _valueRepository,
            taskWriteService: taskWriteService,
            errorReporter: context.read<AppErrorReporter>(),
          ),
          child: TaskDetailSheet(
            defaultProjectId: defaultProjectId,
            defaultValueIds: defaultValueIds,
            defaultStartDate: defaultStartDate,
            defaultDeadlineDate: defaultDeadlineDate,
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
        final projectWriteService = _projectWriteService;
        if (projectWriteService == null) {
          throw StateError(
            'EditorLauncher.openProjectEditor requires a ProjectWriteService.',
          );
        }
        return ProjectEditSheetPage(
          projectId: projectId,
          projectRepository: _projectRepository,
          valueRepository: _valueRepository,
          projectWriteService: projectWriteService,
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
        final valueWriteService = _valueWriteService;
        if (valueWriteService == null) {
          throw StateError(
            'EditorLauncher.openValueEditor requires a ValueWriteService.',
          );
        }
        return ValueDetailSheetPage(
          valueId: valueId,
          valueRepository: _valueRepository,
          valueWriteService: valueWriteService,
          initialDraft: valueId == null ? initialDraft : null,
          onSaved: onSaved,
        );
      },
    );
  }

  Future<void> openRoutineEditor(
    BuildContext context, {
    String? routineId,
    bool? showDragHandle,
  }) {
    final routineRepository = _routineRepository;
    final routineWriteService = _routineWriteService;
    if (routineRepository == null || routineWriteService == null) {
      throw StateError(
        'EditorLauncher.openRoutineEditor requires a RoutineRepositoryContract.',
      );
    }

    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return RoutineDetailSheetPage(
          routineId: routineId,
          routineRepository: routineRepository,
          valueRepository: _valueRepository,
          routineWriteService: routineWriteService,
        );
      },
    );
  }
}
