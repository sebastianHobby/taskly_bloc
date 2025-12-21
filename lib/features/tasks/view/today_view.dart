import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_query.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/features/tasks/widgets/tasks_list.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskOverviewBloc>(
          create: (context) => TaskOverviewBloc(
            taskRepository: taskRepository,
            initialQuery: TaskListQuery.today(now: DateTime.now()),
          )..add(const TaskOverviewEvent.subscriptionRequested()),
        ),
      ],
      child: TodayView(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        valueRepository: valueRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class TodayView extends StatelessWidget {
  const TodayView({
    required this.taskRepository,
    required this.projectRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

  void _showTaskDetailSheet(BuildContext context, {String? taskId}) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: BlocProvider(
            create: (_) => TaskDetailBloc(
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              valueRepository: valueRepository,
              labelRepository: labelRepository,
              taskId: taskId,
            ),
            child: const TaskDetailSheet(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.todayTitle),
      ),
      body: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (tasks, query) => TasksListView(
              tasks: tasks,
              onTap: (task) => _showTaskDetailSheet(context, taskId: task.id),
            ),
            error: (error, _) => Center(
              child: Text(
                friendlyErrorMessageForUi(error, context.l10n),
              ),
            ),
          );
        },
      ),
      floatingActionButton: AddTaskFab(
        onPressed: () => _showTaskDetailSheet(context),
      ),
    );
  }
}
