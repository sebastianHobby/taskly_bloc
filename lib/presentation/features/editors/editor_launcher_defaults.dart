import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routine_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_view.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';

Widget buildDefaultTaskEditor(
  BuildContext context,
  TaskEditorLaunchArgs args,
) {
  return BlocProvider(
    create: (_) => TaskDetailBloc(
      taskId: args.taskId,
      taskRepository: args.taskRepository,
      projectRepository: args.projectRepository,
      valueRepository: args.valueRepository,
      taskWriteService: args.taskWriteService,
      errorReporter: args.errorReporter,
      demoModeService: args.demoModeService,
      demoDataProvider: args.demoDataProvider,
    ),
    child: TaskDetailSheet(
      defaultProjectId: args.defaultProjectId,
      defaultValueIds: args.defaultValueIds,
      defaultStartDate: args.defaultStartDate,
      defaultDeadlineDate: args.defaultDeadlineDate,
      openToValues: args.openToValues,
      openToProjectPicker: args.openToProjectPicker,
    ),
  );
}

Widget buildDefaultProjectEditor(
  BuildContext context,
  ProjectEditorLaunchArgs args,
) {
  return ProjectEditSheetPage(
    projectId: args.projectId,
    projectRepository: args.projectRepository,
    valueRepository: args.valueRepository,
    projectWriteService: args.projectWriteService,
    onSaved: args.onSaved,
    openToValues: args.openToValues,
  );
}

Widget buildDefaultValueEditor(
  BuildContext context,
  ValueEditorLaunchArgs args,
) {
  return ValueDetailSheetPage(
    valueId: args.valueId,
    valueRepository: args.valueRepository,
    valueWriteService: args.valueWriteService,
    initialDraft: args.valueId == null ? args.initialDraft : null,
    onSaved: args.onSaved,
  );
}

Widget buildDefaultRoutineEditor(
  BuildContext context,
  RoutineEditorLaunchArgs args,
) {
  return RoutineDetailSheetPage(
    routineId: args.routineId,
    routineRepository: args.routineRepository,
    valueRepository: args.valueRepository,
    routineWriteService: args.routineWriteService,
  );
}

EditorLauncher buildDefaultEditorLauncher({
  required AppErrorReporter errorReporter,
  required DemoModeService demoModeService,
  required DemoDataProvider demoDataProvider,
  required TaskRepositoryContract taskRepository,
  required ProjectRepositoryContract projectRepository,
  required ValueRepositoryContract valueRepository,
  required RoutineRepositoryContract routineRepository,
  required TaskWriteService taskWriteService,
  required ProjectWriteService projectWriteService,
  required ValueWriteService valueWriteService,
  required RoutineWriteService routineWriteService,
}) {
  return EditorLauncher(
    errorReporter: errorReporter,
    demoModeService: demoModeService,
    demoDataProvider: demoDataProvider,
    taskRepository: taskRepository,
    projectRepository: projectRepository,
    valueRepository: valueRepository,
    routineRepository: routineRepository,
    taskWriteService: taskWriteService,
    projectWriteService: projectWriteService,
    valueWriteService: valueWriteService,
    routineWriteService: routineWriteService,
    taskEditorBuilder: buildDefaultTaskEditor,
    projectEditorBuilder: buildDefaultProjectEditor,
    valueEditorBuilder: buildDefaultValueEditor,
    routineEditorBuilder: buildDefaultRoutineEditor,
  );
}
