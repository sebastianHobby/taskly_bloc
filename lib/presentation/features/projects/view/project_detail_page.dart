import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_overview_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_ui/taskly_ui_feed.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ProjectOverviewBloc(
            projectId: projectId,
            projectRepository: getIt<ProjectRepositoryContract>(),
            occurrenceReadService: getIt<OccurrenceReadService>(),
            sessionDayKeyService: getIt<SessionDayKeyService>(),
          ),
        ),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
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

    return BlocBuilder<SelectionCubit, SelectionState>(
      builder: (context, selectionState) {
        return Scaffold(
          appBar: selectionState.isSelectionMode
              ? SelectionAppBar(
                  baseTitle: 'Project details',
                  onExit: () {},
                )
              : AppBar(
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
                    selectionState: selectionState,
                  ),
              };
            },
          ),
        );
      },
    );
  }
}

class _ProjectDetailBody extends StatelessWidget {
  const _ProjectDetailBody({
    required this.project,
    required this.tasks,
    required this.todayDayKeyUtc,
    required this.selectionState,
  });

  final Project project;
  final List<Task> tasks;
  final DateTime todayDayKeyUtc;
  final SelectionState selectionState;

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (GlobalSettingsBloc bloc) => bloc.state.settings,
    );
    final isInbox = project.id == ProjectGroupingRef.inbox().stableKey;
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
      preset: isInbox
          ? const TasklyProjectRowPreset.inbox()
          : const TasklyProjectRowPreset.standard(),
      actions: const TasklyProjectRowActions(),
    );

    final selection = context.read<SelectionCubit>();
    final visibleTasks = [...open, ...completed];
    _registerVisibleTasks(selection, visibleTasks);

    final rows = <TasklyRowSpec>[
      TasklyRowSpec.header(
        key: 'project-detail-open-header',
        title: 'Tasks',
        trailingLabel: '${open.length} remaining',
      ),
      ...open.map((task) => _taskRow(context, task, selectionState)),
      if (completed.isNotEmpty) ...[
        TasklyRowSpec.header(
          key: 'project-detail-completed-header',
          title: 'Completed',
        ),
        ...completed.map((task) => _taskRow(context, task, selectionState)),
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

  TasklyRowSpec _taskRow(
    BuildContext context,
    Task task,
    SelectionState selectionState,
  ) {
    final selection = context.read<SelectionCubit>();
    final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
    final data = buildTaskRowData(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
    );

    final key = SelectionKey(
      entityType: EntityType.task,
      entityId: task.id,
    );
    final isSelected = selectionState.selected.contains(key);

    final rowData = TasklyTaskRowData(
      id: data.id,
      title: data.title,
      completed: data.completed,
      meta: data.meta,
      leadingChip: data.leadingChip,
      secondaryChips: data.secondaryChips,
      deemphasized: data.deemphasized,
      checkboxSemanticLabel: data.checkboxSemanticLabel,
      labels: data.labels,
      pinned: data.pinned,
      primaryValueIconOnly: true,
    );

    final style = selectionState.isSelectionMode
        ? TasklyTaskRowStyle.bulkSelection(selected: isSelected)
        : const TasklyTaskRowStyle.standard();

    return TasklyRowSpec.task(
      key: 'project-detail-task-${task.id}',
      data: rowData,
      style: style,
      actions: TasklyTaskRowActions(
        onTap: () {
          if (selection.shouldInterceptTapAsSelection()) {
            selection.handleEntityTap(key);
            return;
          }
          buildTaskOpenEditorHandler(context, task: task)();
        },
        onLongPress: () => selection.enterSelectionMode(initialSelection: key),
        onToggleSelected: selectionState.isSelectionMode
            ? () => selection.handleEntityTap(key)
            : null,
        onToggleCompletion: buildTaskToggleCompletionHandler(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        ),
      ),
    );
  }
}

void _registerVisibleTasks(
  SelectionCubit selection,
  List<Task> tasks,
) {
  selection.updateVisibleEntities(
    tasks
        .map(
          (task) => SelectionEntityMeta(
            key: SelectionKey(
              entityType: EntityType.task,
              entityId: task.id,
            ),
            displayName: task.name,
            canDelete: true,
            completed: task.completed,
            pinned: task.isPinned,
            canCompleteSeries: task.isRepeating && !task.seriesEnded,
          ),
        )
        .toList(growable: false),
  );
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
