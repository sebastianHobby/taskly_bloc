import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_query.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';
import 'package:taskly_bloc/routing/routes.dart';

class UpcomingPage extends StatelessWidget {
  const UpcomingPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskOverviewBloc>(
          create: (context) => TaskOverviewBloc(
            taskRepository: taskRepository,
            initialQuery: TaskListQuery.upcoming(now: DateTime.now()).copyWith(
              sort: TaskSort.deadline,
            ),
            withRelated: true,
          )..add(const TaskOverviewEvent.subscriptionRequested()),
        ),
        BlocProvider<ProjectOverviewBloc>(
          create: (context) => ProjectOverviewBloc(
            projectRepository: projectRepository,
            withRelated: true,
          )..add(const ProjectOverviewEvent.projectsSubscriptionRequested()),
        ),
      ],
      child: UpcomingView(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class UpcomingView extends StatelessWidget {
  const UpcomingView({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  bool _matchesOnOrAfterDay(DateTime? candidate, DateTime cutoffDay) {
    if (candidate == null) return false;
    final day = DateTime(candidate.year, candidate.month, candidate.day);
    return !day.isBefore(cutoffDay);
  }

  int _compareNullableDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  int _compareByDeadlineThenStartThenName({
    required DateTime? deadlineA,
    required DateTime? deadlineB,
    required DateTime? startA,
    required DateTime? startB,
    required String nameA,
    required String nameB,
  }) {
    final primary = _compareNullableDate(deadlineA, deadlineB);
    if (primary != 0) return primary;

    final secondary = _compareNullableDate(startA, startB);
    if (secondary != 0) return secondary;

    return nameA.compareTo(nameB);
  }

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
    final now = DateTime.now();
    final tomorrowDay = DateTime(now.year, now.month, now.day + 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.upcomingTitle),
      ),
      body: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
        builder: (context, taskState) {
          return taskState.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                friendlyErrorMessageForUi(error, context.l10n),
              ),
            ),
            loaded: (tasks, _) {
              final sortedTasks = [...tasks]
                ..sort(
                  (a, b) => _compareByDeadlineThenStartThenName(
                    deadlineA: a.deadlineDate,
                    deadlineB: b.deadlineDate,
                    startA: a.startDate,
                    startB: b.startDate,
                    nameA: a.name,
                    nameB: b.name,
                  ),
                );

              return BlocBuilder<ProjectOverviewBloc, ProjectOverviewState>(
                builder: (context, projectState) {
                  return projectState.when(
                    initial: () =>
                        const Center(child: CircularProgressIndicator()),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error) => Center(
                      child: Text(
                        friendlyErrorMessageForUi(error, context.l10n),
                      ),
                    ),
                    loaded: (projects) {
                      final matchingProjects =
                          projects
                              .where(
                                (p) =>
                                    _matchesOnOrAfterDay(
                                      p.startDate,
                                      tomorrowDay,
                                    ) ||
                                    _matchesOnOrAfterDay(
                                      p.deadlineDate,
                                      tomorrowDay,
                                    ),
                              )
                              .toList(growable: false)
                            ..sort(
                              (a, b) => _compareByDeadlineThenStartThenName(
                                deadlineA: a.deadlineDate,
                                deadlineB: b.deadlineDate,
                                startA: a.startDate,
                                startB: b.startDate,
                                nameA: a.name,
                                nameB: b.name,
                              ),
                            );

                      final projectBloc = context.read<ProjectOverviewBloc>();
                      final taskBloc = context.read<TaskOverviewBloc>();

                      return ListView(
                        children: [
                          if (matchingProjects.isNotEmpty)
                            _SectionHeader(title: context.l10n.projectsTitle),
                          for (final project in matchingProjects)
                            ProjectListTile(
                              project: project,
                              onCheckboxChanged: (project, _) {
                                projectBloc.add(
                                  ProjectOverviewEvent.toggleProjectCompletion(
                                    project: project,
                                  ),
                                );
                              },
                              onTap: (project) async {
                                await context.pushNamed(
                                  AppRouteName.projectDetail,
                                  pathParameters: {
                                    'projectId': project.id,
                                  },
                                );
                              },
                            ),
                          if (sortedTasks.isNotEmpty)
                            _SectionHeader(title: context.l10n.tasksTitle),
                          for (final task in sortedTasks)
                            TaskListTile(
                              task: task,
                              onCheckboxChanged: (task, isCompleted) {
                                if (isCompleted == null) return;
                                taskBloc.add(
                                  TaskOverviewEvent.toggleTaskCompletion(
                                    task: task,
                                  ),
                                );
                              },
                              onTap: (task) => _showTaskDetailSheet(
                                context,
                                taskId: task.id,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: AddTaskFab(
        onPressed: () => _showTaskDetailSheet(context),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall,
      ),
    );
  }
}
