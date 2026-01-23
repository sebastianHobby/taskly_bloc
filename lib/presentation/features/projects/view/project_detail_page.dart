import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_overview_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectOverviewBloc(
        projectId: projectId,
        projectRepository: getIt<ProjectRepositoryContract>(),
        occurrenceReadService: getIt<OccurrenceReadService>(),
        sessionDayKeyService: getIt<SessionDayKeyService>(),
      ),
      child: const _ProjectDetailView(),
    );
  }
}

class _ProjectDetailView extends StatelessWidget {
  const _ProjectDetailView();

  @override
  Widget build(BuildContext context) {
    final chrome = TasklyChromeTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final iconButtonStyle = IconButton.styleFrom(
      backgroundColor: scheme.surfaceContainerHighest.withValues(
        alpha: chrome.iconButtonBackgroundAlpha,
      ),
      foregroundColor: scheme.onSurface,
      shape: const CircleBorder(),
      minimumSize: Size.square(chrome.iconButtonMinSize),
      padding: chrome.iconButtonPadding,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: chrome.anytimeAppBarHeight,
        title: const Text('Project details'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          style: iconButtonStyle,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            style: iconButtonStyle,
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<ProjectOverviewBloc, ProjectOverviewState>(
        builder: (context, state) {
          return switch (state) {
            ProjectOverviewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProjectOverviewError(:final message) => Center(
              child: Text(message),
            ),
            ProjectOverviewLoaded(
              :final project,
              :final tasks,
              :final todayDayKeyUtc,
            ) =>
              _ProjectDetailBody(
                project: project,
                tasks: tasks,
                todayDayKeyUtc: todayDayKeyUtc,
              ),
          };
        },
      ),
    );
  }
}

class _ProjectDetailBody extends StatelessWidget {
  const _ProjectDetailBody({
    required this.project,
    required this.tasks,
    required this.todayDayKeyUtc,
  });

  final Project project;
  final List<Task> tasks;
  final DateTime todayDayKeyUtc;

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (GlobalSettingsBloc bloc) => bloc.state.settings,
    );
    final dueSoonCount = _countDueSoon(
      tasks,
      todayDayKeyUtc,
      settings.myDayDueWindowDays,
    );

    final completed = tasks
        .where((task) => task.occurrence?.isCompleted ?? task.completed)
        .toList();
    final open = tasks
        .where((task) => !(task.occurrence?.isCompleted ?? task.completed))
        .toList();

    final headerData = buildProjectRowData(
      context,
      project: project,
      taskCount: tasks.length,
      completedTaskCount: completed.length,
      dueSoonCount: dueSoonCount,
    );

    final headerRow = TasklyRowSpec.project(
      key: 'project-detail-header',
      data: headerData,
      preset: const TasklyProjectRowPreset.standard(),
      actions: const TasklyProjectRowActions(),
    );

    final rows = <TasklyRowSpec>[
      TasklyRowSpec.header(
        key: 'project-detail-open-header',
        title: 'Tasks',
        trailingLabel: '${open.length} remaining',
      ),
      ...open.map((task) => _taskRow(context, task)),
      if (completed.isNotEmpty) ...[
        TasklyRowSpec.header(
          key: 'project-detail-completed-header',
          title: 'Completed',
        ),
        ...completed.map((task) => _taskRow(context, task)),
      ],
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TasklyFeedRenderer.buildRow(headerRow, context: context),
        const SizedBox(height: 12),
        TasklyFeedRenderer.buildSection(
          TasklySectionSpec.standardList(id: 'project-detail', rows: rows),
        ),
      ],
    );
  }

  TasklyRowSpec _taskRow(BuildContext context, Task task) {
    final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
    final data = buildTaskRowData(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
    );

    return TasklyRowSpec.task(
      key: 'project-detail-task-${task.id}',
      data: data,
      markers: TasklyTaskRowMarkers(pinned: task.isPinned),
      preset: const TasklyTaskRowPreset.standard(),
      actions: TasklyTaskRowActions(
        onTap: buildTaskOpenEditorHandler(context, task: task),
        onToggleCompletion: buildTaskToggleCompletionHandler(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        ),
      ),
    );
  }
}

int _countDueSoon(
  List<Task> tasks,
  DateTime todayDayKeyUtc,
  int dueWindowDays,
) {
  final today = DateTime.utc(
    todayDayKeyUtc.year,
    todayDayKeyUtc.month,
    todayDayKeyUtc.day,
  );
  final dueLimit = today.add(
    Duration(days: dueWindowDays.clamp(1, 30) - 1),
  );

  int count = 0;
  for (final task in tasks) {
    if (task.occurrence?.isCompleted ?? task.completed) continue;
    final deadline = task.occurrence?.deadline ?? task.deadlineDate;
    if (deadline == null) continue;
    final deadlineDay = DateTime.utc(
      deadline.year,
      deadline.month,
      deadline.day,
    );
    if (!deadlineDay.isBefore(today) && !deadlineDay.isAfter(dueLimit)) {
      count += 1;
    }
  }
  return count;
}
