import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';

@immutable
class TaskEditorLaunchArgs {
  const TaskEditorLaunchArgs({
    required this.taskRepository,
    required this.projectRepository,
    required this.valueRepository,
    required this.taskWriteService,
    required this.taskMyDayWriteService,
    required this.errorReporter,
    required this.demoModeService,
    required this.demoDataProvider,
    this.taskId,
    this.defaultProjectId,
    this.defaultValueIds,
    this.defaultStartDate,
    this.defaultDeadlineDate,
    this.openToValues = false,
    this.openToProjectPicker = false,
    this.includeInMyDayDefault = false,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final TaskWriteService taskWriteService;
  final TaskMyDayWriteService taskMyDayWriteService;
  final AppErrorReporter errorReporter;
  final DemoModeService demoModeService;
  final DemoDataProvider demoDataProvider;
  final String? taskId;
  final String? defaultProjectId;
  final List<String>? defaultValueIds;
  final DateTime? defaultStartDate;
  final DateTime? defaultDeadlineDate;
  final bool openToValues;
  final bool openToProjectPicker;
  final bool includeInMyDayDefault;
}

typedef TaskEditorBuilder =
    Widget Function(BuildContext context, TaskEditorLaunchArgs args);

@immutable
class ProjectEditorLaunchArgs {
  const ProjectEditorLaunchArgs({
    required this.projectRepository,
    required this.valueRepository,
    required this.projectWriteService,
    this.projectId,
    this.onSaved,
    this.openToValues = false,
  });

  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final ProjectWriteService projectWriteService;
  final String? projectId;
  final void Function(String projectId)? onSaved;
  final bool openToValues;
}

typedef ProjectEditorBuilder =
    Widget Function(BuildContext context, ProjectEditorLaunchArgs args);

@immutable
class ValueEditorLaunchArgs {
  const ValueEditorLaunchArgs({
    required this.valueRepository,
    required this.valueWriteService,
    this.valueId,
    this.initialDraft,
    this.onSaved,
  });

  final ValueRepositoryContract valueRepository;
  final ValueWriteService valueWriteService;
  final String? valueId;
  final ValueDraft? initialDraft;
  final void Function(String valueId)? onSaved;
}

typedef ValueEditorBuilder =
    Widget Function(BuildContext context, ValueEditorLaunchArgs args);

@immutable
class RoutineEditorLaunchArgs {
  const RoutineEditorLaunchArgs({
    required this.routineRepository,
    required this.valueRepository,
    required this.routineWriteService,
    this.routineId,
  });

  final RoutineRepositoryContract routineRepository;
  final ValueRepositoryContract valueRepository;
  final RoutineWriteService routineWriteService;
  final String? routineId;
}

typedef RoutineEditorBuilder =
    Widget Function(BuildContext context, RoutineEditorLaunchArgs args);

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
    required AppErrorReporter errorReporter,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    TaskRepositoryContract? taskRepository,
    RoutineRepositoryContract? routineRepository,
    TaskWriteService? taskWriteService,
    TaskMyDayWriteService? taskMyDayWriteService,
    ProjectWriteService? projectWriteService,
    ValueWriteService? valueWriteService,
    RoutineWriteService? routineWriteService,
    TaskEditorBuilder? taskEditorBuilder,
    ProjectEditorBuilder? projectEditorBuilder,
    ValueEditorBuilder? valueEditorBuilder,
    RoutineEditorBuilder? routineEditorBuilder,
  }) : _errorReporter = errorReporter,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider,
       _taskRepository = taskRepository,
       _routineRepository = routineRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _taskWriteService = taskWriteService,
       _taskMyDayWriteService = taskMyDayWriteService,
       _projectWriteService = projectWriteService,
       _valueWriteService = valueWriteService,
       _routineWriteService = routineWriteService,
       _taskEditorBuilder = taskEditorBuilder,
       _projectEditorBuilder = projectEditorBuilder,
       _valueEditorBuilder = valueEditorBuilder,
       _routineEditorBuilder = routineEditorBuilder;

  final TaskRepositoryContract? _taskRepository;
  final RoutineRepositoryContract? _routineRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final TaskWriteService? _taskWriteService;
  final TaskMyDayWriteService? _taskMyDayWriteService;
  final ProjectWriteService? _projectWriteService;
  final ValueWriteService? _valueWriteService;
  final RoutineWriteService? _routineWriteService;
  final TaskEditorBuilder? _taskEditorBuilder;
  final ProjectEditorBuilder? _projectEditorBuilder;
  final ValueEditorBuilder? _valueEditorBuilder;
  final RoutineEditorBuilder? _routineEditorBuilder;
  final AppErrorReporter _errorReporter;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;

  Future<void> openTaskEditor(
    BuildContext context, {
    String? taskId,
    String? defaultProjectId,
    List<String>? defaultValueIds,
    DateTime? defaultStartDate,
    DateTime? defaultDeadlineDate,
    bool openToValues = false,
    bool openToProjectPicker = false,
    bool includeInMyDayDefault = false,
    bool? showDragHandle,
  }) {
    final taskRepository = _taskRepository;
    final taskWriteService = _taskWriteService;
    final taskMyDayWriteService = _taskMyDayWriteService;
    if (taskRepository == null || taskWriteService == null) {
      throw StateError(
        'EditorLauncher.openTaskEditor requires a TaskRepositoryContract.',
      );
    }
    if (taskMyDayWriteService == null) {
      throw StateError(
        'EditorLauncher.openTaskEditor requires a TaskMyDayWriteService.',
      );
    }
    final taskEditorBuilder = _taskEditorBuilder;
    if (taskEditorBuilder == null) {
      throw StateError(
        'EditorLauncher.openTaskEditor requires a TaskEditorBuilder.',
      );
    }

    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return taskEditorBuilder(
          modalContext,
          TaskEditorLaunchArgs(
            taskRepository: taskRepository,
            projectRepository: _projectRepository,
            valueRepository: _valueRepository,
            taskWriteService: taskWriteService,
            taskMyDayWriteService: taskMyDayWriteService,
            errorReporter: _errorReporter,
            demoModeService: _demoModeService,
            demoDataProvider: _demoDataProvider,
            taskId: taskId,
            defaultProjectId: defaultProjectId,
            defaultValueIds: defaultValueIds,
            defaultStartDate: defaultStartDate,
            defaultDeadlineDate: defaultDeadlineDate,
            openToValues: openToValues,
            openToProjectPicker: openToProjectPicker,
            includeInMyDayDefault: includeInMyDayDefault,
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
    final projectWriteService = _projectWriteService;
    if (projectWriteService == null) {
      throw StateError(
        'EditorLauncher.openProjectEditor requires a ProjectWriteService.',
      );
    }
    final projectEditorBuilder = _projectEditorBuilder;
    if (projectEditorBuilder == null) {
      throw StateError(
        'EditorLauncher.openProjectEditor requires a ProjectEditorBuilder.',
      );
    }

    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return projectEditorBuilder(
          modalContext,
          ProjectEditorLaunchArgs(
            projectRepository: _projectRepository,
            valueRepository: _valueRepository,
            projectWriteService: projectWriteService,
            projectId: projectId,
            onSaved: onSaved,
            openToValues: openToValues,
          ),
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
    final valueWriteService = _valueWriteService;
    if (valueWriteService == null) {
      throw StateError(
        'EditorLauncher.openValueEditor requires a ValueWriteService.',
      );
    }
    final valueEditorBuilder = _valueEditorBuilder;
    if (valueEditorBuilder == null) {
      throw StateError(
        'EditorLauncher.openValueEditor requires a ValueEditorBuilder.',
      );
    }

    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return valueEditorBuilder(
          modalContext,
          ValueEditorLaunchArgs(
            valueRepository: _valueRepository,
            valueWriteService: valueWriteService,
            valueId: valueId,
            initialDraft: valueId == null ? initialDraft : null,
            onSaved: onSaved,
          ),
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
    final routineEditorBuilder = _routineEditorBuilder;
    if (routineEditorBuilder == null) {
      throw StateError(
        'EditorLauncher.openRoutineEditor requires a RoutineEditorBuilder.',
      );
    }

    final windowSizeClass = WindowSizeClass.of(context);
    final effectiveShowDragHandle =
        windowSizeClass.isCompact && (showDragHandle ?? true);

    return showDetailModal<void>(
      context: context,
      showDragHandle: effectiveShowDragHandle,
      childBuilder: (modalContext) {
        return routineEditorBuilder(
          modalContext,
          RoutineEditorLaunchArgs(
            routineRepository: routineRepository,
            valueRepository: _valueRepository,
            routineWriteService: routineWriteService,
            routineId: routineId,
          ),
        );
      },
    );
  }
}
