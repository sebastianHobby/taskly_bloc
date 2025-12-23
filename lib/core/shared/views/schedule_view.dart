import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/views/schedule_view_config.dart';
import 'package:taskly_bloc/core/shared/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/shared/widgets/section_header.dart';
import 'package:taskly_bloc/core/shared/widgets/sort_bottom_sheet.dart';
import 'package:taskly_bloc/core/shared/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/features/settings/settings.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/features/tasks/widgets/tasks_list.dart';
import 'package:taskly_bloc/routing/routes.dart';

/// A page wrapper that sets up BLoC providers for a schedule view.
///
/// This handles the common pattern of reading saved sort preferences and
/// creating TaskOverviewBloc and ProjectOverviewBloc with appropriate configs.
class SchedulePage extends StatelessWidget {
  const SchedulePage({
    required this.config,
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final ScheduleViewConfig config;
  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    final settingsState = context.read<SettingsBloc>().state;
    final savedSort = settingsState.settings?.sortFor(config.pageKey);
    final effectiveSort = savedSort ?? config.defaultSortPreferences;
    final now = DateTime.now();

    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskOverviewBloc>(
          create: (context) => TaskOverviewBloc(
            taskRepository: taskRepository,
            initialConfig: config.taskSelectorFactory(
              now,
              effectiveSort.criteria,
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
          )..add(const ProjectOverviewEvent.subscriptionRequested()),
        ),
      ],
      child: ScheduleView(
        config: config,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

/// The main schedule view widget that displays tasks and projects.
///
/// This is a reusable view that can be configured via [ScheduleViewConfig]
/// to work for different schedule types (Today, Upcoming, etc.).
class ScheduleView extends StatefulWidget {
  const ScheduleView({
    required this.config,
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final ScheduleViewConfig config;
  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  ScheduleViewConfig get _config => widget.config;

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
            child: TaskDetailSheet(labelRepository: widget.labelRepository),
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
      orElse: () => _config.taskSelectorFactory(
        DateTime.now(),
        _config.defaultSortPreferences.criteria,
      ),
    );

    await showSortBottomSheet(
      context: context,
      current: SortPreferences(criteria: taskQuery.sortCriteria),
      availableSortFields: _config.availableSortFields,
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
            pageKey: _config.pageKey,
            preferences: updated,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoffDay = _config.getCutoffDay(now);

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        final previousSort = previous.settings
            ?.sortFor(_config.pageKey)
            ?.criteria;
        final currentSort = current.settings
            ?.sortFor(_config.pageKey)
            ?.criteria;
        return previousSort != currentSort;
      },
      listener: (context, state) {
        final preferences = state.settings?.sortFor(_config.pageKey);
        if (preferences == null) return;

        final taskBloc = context.read<TaskOverviewBloc>();
        final projectBloc = context.read<ProjectOverviewBloc>();

        final taskQuery = taskBloc.state.maybeWhen(
          loaded: (_, config) => config,
          orElse: () => _config.taskSelectorFactory(
            DateTime.now(),
            _config.defaultSortPreferences.criteria,
          ),
        );

        if (taskQuery.sortCriteria != preferences.criteria) {
          taskBloc.add(
            TaskOverviewEvent.configChanged(
              config: taskQuery.copyWith(sortCriteria: preferences.criteria),
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
          title: Text(_config.titleBuilder(context)),
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
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(friendlyErrorMessageForUi(error, context.l10n)),
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
                        return _buildContent(
                          context,
                          tasks: tasks,
                          projects: projects,
                          taskCounts: taskCounts,
                          cutoffDay: cutoffDay,
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
          taskRepository: widget.taskRepository,
          projectRepository: widget.projectRepository,
          labelRepository: widget.labelRepository,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required List<Task> tasks,
    required List<Project> projects,
    required Map<String, ProjectTaskCounts> taskCounts,
    required DateTime cutoffDay,
  }) {
    final matchingProjects = projects
        .where(
          (p) => _config.projectMatcher(p.startDate, p.deadlineDate, cutoffDay),
        )
        .toList(growable: false);

    final hasProjects = matchingProjects.isNotEmpty;
    final hasTasks = tasks.isNotEmpty;
    final isEmpty = !hasProjects && !hasTasks;

    final banner = _config.bannerBuilder?.call(context);

    if (isEmpty) {
      if (banner != null) {
        return Column(
          children: [
            banner,
            Expanded(child: _config.emptyStateBuilder(context)),
          ],
        );
      }
      return _config.emptyStateBuilder(context);
    }

    final content = ListView(
      children: [
        if (hasProjects) ...[
          SectionHeader.simple(title: context.l10n.projectsTitle),
          ..._buildProjectsList(context, matchingProjects, taskCounts),
        ],
        if (hasTasks) ...[
          SectionHeader.simple(title: context.l10n.tasksTitle),
          TasksListView(
            tasks: tasks,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onTap: (task) => _showTaskDetailSheet(context, taskId: task.id),
          ),
        ],
      ],
    );

    if (banner != null) {
      return Column(
        children: [
          banner,
          Expanded(child: content),
        ],
      );
    }
    return content;
  }

  List<Widget> _buildProjectsList(
    BuildContext context,
    List<Project> projects,
    Map<String, ProjectTaskCounts> taskCounts,
  ) {
    return projects.map((project) {
      final counts = taskCounts[project.id];
      return SwipeToDelete(
        itemKey: ValueKey(project.id),
        confirmDismiss: () => showDeleteConfirmationDialog(
          context: context,
          title: 'Delete Project',
          itemName: project.name,
          description:
              'All tasks in this project will also be deleted. '
              'This action cannot be undone.',
        ),
        onDismissed: () {
          context.read<ProjectOverviewBloc>().add(
            ProjectOverviewEvent.deleteProject(project: project),
          );
          showDeleteSnackBar(context: context, message: 'Project deleted');
        },
        child: ProjectListTile(
          project: project,
          taskCount: counts?.totalCount,
          completedTaskCount: counts?.completedCount,
          onCheckboxChanged: (project, _) {
            context.read<ProjectOverviewBloc>().add(
              ProjectOverviewEvent.toggleProjectCompletion(project: project),
            );
          },
          onTap: (project) async {
            await context.pushNamed(
              AppRouteName.projectDetail,
              pathParameters: {'projectId': project.id},
            );
          },
        ),
      );
    }).toList();
  }
}
