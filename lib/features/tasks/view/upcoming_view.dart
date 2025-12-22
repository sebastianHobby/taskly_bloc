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
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/features/tasks/widgets/tasks_list.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/widgets/sort_bottom_sheet.dart';
import 'package:taskly_bloc/features/settings/settings.dart';
import 'package:taskly_bloc/routing/routes.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
import 'package:taskly_bloc/core/shared/widgets/empty_state_widget.dart';

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
    const defaultSort = SortPreferences();

    final settingsState = context.read<SettingsBloc>().state;
    final savedSort = settingsState.settings?.sortFor(SettingsPageKey.upcoming);
    final effectiveSort = savedSort ?? defaultSort;

    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskOverviewBloc>(
          create: (context) => TaskOverviewBloc(
            taskRepository: taskRepository,
            initialConfig: TaskSelector.upcoming(
              now: DateTime.now(),
              sortCriteria: effectiveSort.criteria,
            ),
            withRelated: true,
          )..add(const TaskOverviewEvent.subscriptionRequested()),
        ),
        BlocProvider<ProjectOverviewBloc>(
          create: (context) => ProjectOverviewBloc(
            projectRepository: projectRepository,
            taskRepository: taskRepository,
            withRelated: true,
            initialSortPreferences: effectiveSort,
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

class UpcomingView extends StatefulWidget {
  const UpcomingView({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  State<UpcomingView> createState() => _UpcomingViewState();
}

class _UpcomingViewState extends State<UpcomingView> {
  bool _matchesOnOrAfterDay(DateTime? candidate, DateTime cutoffDay) {
    if (candidate == null) return false;
    final day = DateTime(candidate.year, candidate.month, candidate.day);
    return !day.isBefore(cutoffDay);
  }

  void _showTaskDetailSheet(BuildContext context, {String? taskId}) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: BlocProvider(
            create: (_) => TaskDetailBloc(
              taskRepository: widget.taskRepository,
              projectRepository: widget.projectRepository,
              labelRepository: widget.labelRepository,
              taskId: taskId,
            ),
            child: const TaskDetailSheet(),
          ),
        ),
      ),
    );
  }

  Future<void> _openGroupSortSheet() async {
    final taskBloc = context.read<TaskOverviewBloc>();
    final projectBloc = context.read<ProjectOverviewBloc>();
    final taskQuery = taskBloc.state.maybeWhen(
      loaded: (_, config) => config,
      orElse: () => TaskSelector.upcoming(now: DateTime.now()),
    );

    await showSortBottomSheet(
      context: context,
      current: SortPreferences(criteria: taskQuery.sortCriteria),
      availableSortFields: const [
        SortField.deadlineDate,
        SortField.startDate,
        SortField.name,
      ],
      onChanged: (updated) {
        taskBloc.add(
          TaskOverviewEvent.configChanged(
            config: taskQuery.copyWith(sortCriteria: updated.criteria),
          ),
        );
        projectBloc.add(
          ProjectOverviewEvent.sortChanged(preferences: updated),
        );
        context.read<SettingsBloc>().add(
          SettingsUpdatePageSort(
            pageKey: SettingsPageKey.upcoming,
            preferences: updated,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrowDay = DateTime(now.year, now.month, now.day + 1);

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        final previousSort = previous.settings
            ?.sortFor(SettingsPageKey.upcoming)
            ?.criteria;
        final currentSort = current.settings
            ?.sortFor(SettingsPageKey.upcoming)
            ?.criteria;
        return previousSort != currentSort;
      },
      listener: (context, state) {
        final preferences = state.settings?.sortFor(SettingsPageKey.upcoming);
        if (preferences == null) return;

        final taskBloc = context.read<TaskOverviewBloc>();
        final projectBloc = context.read<ProjectOverviewBloc>();

        final taskQuery = taskBloc.state.maybeWhen(
          loaded: (_, config) => config,
          orElse: () => TaskSelector.upcoming(now: DateTime.now()),
        );

        if (taskQuery.sortCriteria != preferences.criteria) {
          taskBloc.add(
            TaskOverviewEvent.configChanged(
              config: taskQuery.copyWith(
                sortCriteria: preferences.criteria,
              ),
            ),
          );
        }

        if (projectBloc.currentSortPreferences != preferences) {
          projectBloc.add(
            ProjectOverviewEvent.sortChanged(preferences: preferences),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.upcomingTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              tooltip: context.l10n.sortMenuTitle,
              onPressed: _openGroupSortSheet,
            ),
          ],
        ),
        body: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
          builder: (context, taskState) {
            return taskState.when(
              initial: () => const Center(
                child: CircularProgressIndicator(),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text(
                  friendlyErrorMessageForUi(error, context.l10n),
                ),
              ),
              loaded: (tasks, _) {
                return BlocBuilder<ProjectOverviewBloc, ProjectOverviewState>(
                  builder: (context, projectState) {
                    return projectState.when(
                      initial: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error) => Center(
                        child: Text(
                          friendlyErrorMessageForUi(error, context.l10n),
                        ),
                      ),
                      loaded: (projects, taskCounts) {
                        final matchingProjects = projects
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
                            .toList(growable: false);

                        final hasProjects = matchingProjects.isNotEmpty;
                        final hasTasks = tasks.isNotEmpty;
                        final isEmpty = !hasProjects && !hasTasks;

                        if (isEmpty) {
                          return EmptyStateWidget.upcoming(
                            title: context.l10n.emptyUpcomingTitle,
                            description: context.l10n.emptyUpcomingDescription,
                          );
                        }

                        return ListView(
                          children: [
                            if (hasProjects) ...[
                              _SectionHeader(
                                title: context.l10n.projectsTitle,
                              ),
                              ...matchingProjects.map(
                                (project) {
                                  final counts = taskCounts[project.id];
                                  return ProjectListTile(
                                    project: project,
                                    taskCount: counts?.totalCount,
                                    completedTaskCount: counts?.completedCount,
                                    onCheckboxChanged: (project, _) {
                                      context.read<ProjectOverviewBloc>().add(
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
                                  );
                                },
                              ),
                            ],
                            if (hasTasks) ...[
                              _SectionHeader(
                                title: context.l10n.tasksTitle,
                              ),
                              TasksListView(
                                tasks: tasks,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                onTap: (task) => _showTaskDetailSheet(
                                  context,
                                  taskId: task.id,
                                ),
                              ),
                            ],
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
