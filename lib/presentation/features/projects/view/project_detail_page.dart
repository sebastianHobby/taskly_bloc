import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_overview_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
            projectNextActionsRepository:
                getIt<ProjectNextActionsRepositoryContract>(),
            sessionDayKeyService: getIt<SessionDayKeyService>(),
          ),
        ),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: _ProjectDetailView(projectId: projectId),
    );
  }
}

class _ProjectDetailView extends StatelessWidget {
  const _ProjectDetailView({required this.projectId});

  final String projectId;

  Future<void> _openNewTaskEditor(BuildContext context) {
    final inboxId = ProjectGroupingRef.inbox().stableKey;
    final defaultProjectId = projectId == inboxId ? null : projectId;

    return EditorLauncher.fromGetIt().openTaskEditor(
      context,
      taskId: null,
      defaultProjectId: defaultProjectId,
      showDragHandle: true,
    );
  }

  Future<void> _openNewProjectEditor(BuildContext context) {
    return EditorLauncher.fromGetIt().openProjectEditor(
      context,
      projectId: null,
      showDragHandle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = TasklyTokens.of(context);
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
          floatingActionButton: selectionState.isSelectionMode
              ? null
              : EntityAddSpeedDial(
                  heroTag: 'add_speed_dial_project_detail',
                  onCreateTask: () => _openNewTaskEditor(context),
                  onCreateProject: () => _openNewProjectEditor(context),
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
                  :final nextActions,
                ) =>
                  _ProjectDetailBody(
                    project: project,
                    tasks: tasks,
                    todayDayKeyUtc: todayDayKeyUtc,
                    nextActions: nextActions,
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
    required this.nextActions,
    required this.selectionState,
  });

  final Project project;
  final List<Task> tasks;
  final DateTime todayDayKeyUtc;
  final List<ProjectNextAction> nextActions;
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

    final orderedNextActions = List<ProjectNextAction>.from(nextActions)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final tasksById = {for (final task in tasks) task.id: task};
    final nextActionEntries = _buildNextActionEntries(
      orderedNextActions,
      tasksById: tasksById,
    );
    final nextActionTaskIds = nextActionEntries
        .map((entry) => entry.task.id)
        .toSet();
    final remainingOpen = open
        .where((task) => !nextActionTaskIds.contains(task.id))
        .toList(growable: false);

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
    final visibleTasks = [
      ...nextActionEntries.map((entry) => entry.task),
      ...remainingOpen,
      ...completed,
    ];
    _registerVisibleTasks(selection, visibleTasks);

    final rows = <TasklyRowSpec>[
      TasklyRowSpec.header(
        key: 'project-detail-open-header',
        title: 'Tasks',
        trailingLabel: '${remainingOpen.length} remaining',
      ),
      ...remainingOpen.map(
        (task) => _buildProjectTaskRow(context, task, selectionState),
      ),
      if (completed.isNotEmpty) ...[
        TasklyRowSpec.header(
          key: 'project-detail-completed-header',
          title: 'Completed',
        ),
        ...completed.map(
          (task) => _buildProjectTaskRow(context, task, selectionState),
        ),
      ],
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceSm,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
      children: [
        TasklyFeedRenderer.buildRow(headerRow, context: context),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (!isInbox)
          _ProjectNextActionsSection(
            entries: nextActionEntries,
            selectionState: selectionState,
            onPickRequested: () => _showNextActionPicker(
              context,
              availableTasks: remainingOpen,
              existingActions: orderedNextActions,
              tasksById: tasksById,
            ),
            onRemoveRequested: (taskId) => _removeNextAction(
              context,
              taskId: taskId,
              existingActions: orderedNextActions,
            ),
            onReorderRequested: (entries) => _reorderNextActions(
              context,
              entries: entries,
            ),
          ),
        if (!isInbox) SizedBox(height: TasklyTokens.of(context).spaceSm),
        TasklyFeedRenderer.buildSection(
          TasklySectionSpec.standardList(id: 'project-detail', rows: rows),
        ),
      ],
    );
  }

  List<_NextActionEntry> _buildNextActionEntries(
    List<ProjectNextAction> actions, {
    required Map<String, Task> tasksById,
  }) {
    final entries = <_NextActionEntry>[];
    for (final action in actions) {
      final task = tasksById[action.taskId];
      if (task == null) continue;
      if (task.occurrence?.isCompleted ?? task.completed) continue;
      entries.add(_NextActionEntry(action: action, task: task));
    }
    return entries;
  }

  Future<void> _showNextActionPicker(
    BuildContext context, {
    required List<Task> availableTasks,
    required List<ProjectNextAction> existingActions,
    required Map<String, Task> tasksById,
  }) async {
    final l10n = context.l10n;
    final parentContext = context;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final rows = availableTasks
            .map((task) {
              final data = buildTaskRowData(
                sheetContext,
                task: task,
                tileCapabilities: EntityTileCapabilitiesResolver.forTask(task),
              );

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

              return TasklyRowSpec.task(
                key: 'project-next-action-pick-${task.id}',
                data: rowData,
                style: const TasklyTaskRowStyle.pickerAction(selected: false),
                actions: TasklyTaskRowActions(
                  onToggleSelected: () async {
                    Navigator.of(sheetContext).pop();
                    final rank = await _showNextActionRankPicker(
                      parentContext,
                      existingActions: existingActions,
                      tasksById: tasksById,
                    );
                    if (rank == null) return;
                    final drafts = _draftsForAddOrReplace(
                      actions: existingActions,
                      taskId: task.id,
                      rank: rank,
                    );
                    if (!parentContext.mounted) return;
                    parentContext.read<ProjectOverviewBloc>().add(
                      ProjectOverviewNextActionsUpdated(
                        actions: drafts,
                        intent: 'add_next_action',
                      ),
                    );
                  },
                ),
              );
            })
            .toList(growable: false);

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(
              TasklyTokens.of(context).spaceLg,
              0,
              TasklyTokens.of(context).spaceLg,
              TasklyTokens.of(context).spaceXl,
            ),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.projectNextActionsPickerTitle),
                subtitle: Text(l10n.projectNextActionsPickerSubtitle),
              ),
              if (rows.isEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: TasklyTokens.of(context).spaceSm,
                  ),
                  child: Text(
                    l10n.projectNextActionsEmptyLabel,
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: Theme.of(
                            sheetContext,
                          ).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                for (final row in rows) ...[
                  TasklyFeedRenderer.buildRow(row, context: sheetContext),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<int?> _showNextActionRankPicker(
    BuildContext context, {
    required List<ProjectNextAction> existingActions,
    required Map<String, Task> tasksById,
  }) {
    final l10n = context.l10n;
    final actionsByRank = {
      for (final action in existingActions) action.rank: action,
    };

    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListView(
          shrinkWrap: true,
          children: [
            for (var rank = 1; rank <= 3; rank += 1)
              ListTile(
                title: Text(l10n.projectNextActionsRankLabel(rank)),
                subtitle: actionsByRank[rank] == null
                    ? null
                    : Text(
                        tasksById[actionsByRank[rank]!.taskId]?.name ?? 'Task',
                      ),
                onTap: () => Navigator.of(sheetContext).pop(rank),
              ),
          ],
        );
      },
    );
  }

  void _removeNextAction(
    BuildContext context, {
    required String taskId,
    required List<ProjectNextAction> existingActions,
  }) {
    final drafts = _draftsForRemoval(existingActions, taskId);
    context.read<ProjectOverviewBloc>().add(
      ProjectOverviewNextActionsUpdated(
        actions: drafts,
        intent: 'remove_next_action',
      ),
    );
  }

  void _reorderNextActions(
    BuildContext context, {
    required List<_NextActionEntry> entries,
  }) {
    final drafts = _draftsForReorder(entries);
    context.read<ProjectOverviewBloc>().add(
      ProjectOverviewNextActionsUpdated(
        actions: drafts,
        intent: 'reorder_next_actions',
      ),
    );
  }

  List<ProjectNextActionDraft> _draftsForReorder(
    List<_NextActionEntry> entries,
  ) {
    return [
      for (var i = 0; i < entries.length; i += 1)
        ProjectNextActionDraft(
          taskId: entries[i].task.id,
          rank: i + 1,
        ),
    ];
  }

  List<ProjectNextActionDraft> _draftsForRemoval(
    List<ProjectNextAction> actions,
    String taskId,
  ) {
    final remaining =
        actions
            .where((action) => action.taskId != taskId)
            .toList(growable: false)
          ..sort((a, b) => a.rank.compareTo(b.rank));

    return [
      for (var i = 0; i < remaining.length; i += 1)
        ProjectNextActionDraft(
          taskId: remaining[i].taskId,
          rank: i + 1,
        ),
    ];
  }

  List<ProjectNextActionDraft> _draftsForAddOrReplace({
    required List<ProjectNextAction> actions,
    required String taskId,
    required int rank,
  }) {
    final filtered = actions
        .where((action) => action.rank != rank && action.taskId != taskId)
        .map(
          (action) => ProjectNextActionDraft(
            taskId: action.taskId,
            rank: action.rank,
          ),
        )
        .toList(growable: false);

    return [
      ...filtered,
      ProjectNextActionDraft(taskId: taskId, rank: rank),
    ]..sort((a, b) => a.rank.compareTo(b.rank));
  }
}

class _ProjectNextActionsSection extends StatefulWidget {
  const _ProjectNextActionsSection({
    required this.entries,
    required this.selectionState,
    required this.onPickRequested,
    required this.onRemoveRequested,
    required this.onReorderRequested,
  });

  final List<_NextActionEntry> entries;
  final SelectionState selectionState;
  final VoidCallback onPickRequested;
  final ValueChanged<String> onRemoveRequested;
  final ValueChanged<List<_NextActionEntry>> onReorderRequested;

  @override
  State<_ProjectNextActionsSection> createState() =>
      _ProjectNextActionsSectionState();
}

class _ProjectNextActionsSectionState
    extends State<_ProjectNextActionsSection> {
  late List<_NextActionEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<_NextActionEntry>.from(widget.entries);
  }

  @override
  void didUpdateWidget(covariant _ProjectNextActionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasSameEntries(widget.entries, _entries)) {
      _entries = List<_NextActionEntry>.from(widget.entries);
    }
  }

  bool _hasSameEntries(
    List<_NextActionEntry> incoming,
    List<_NextActionEntry> current,
  ) {
    if (incoming.length != current.length) return false;
    for (var i = 0; i < incoming.length; i += 1) {
      final a = incoming[i];
      final b = current[i];
      if (a.action.taskId != b.action.taskId ||
          a.action.rank != b.action.rank) {
        return false;
      }
    }
    return true;
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      final effectiveIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final entry = _entries.removeAt(oldIndex);
      _entries.insert(effectiveIndex, entry);
    });
    widget.onReorderRequested(List<_NextActionEntry>.from(_entries));
  }

  Future<void> _showActionSheet(_NextActionEntry entry) async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(l10n.projectNextActionsRemoveAction),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (result ?? false) {
      widget.onRemoveRequested(entry.task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final countLabel = l10n.projectNextActionsCountLabel(
      _entries.length,
      3,
    );

    final header = TasklyRowSpec.header(
      key: 'project-next-actions-header',
      title: l10n.projectNextActionsTitle,
      trailingLabel: countLabel,
    );

    final pickerRow = TasklyRowSpec.inlineAction(
      key: 'project-next-actions-picker',
      label: l10n.projectNextActionsChooseAction,
      onTap: widget.onPickRequested,
    );

    final rows = _entries
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final item = entry.value;
          final rowSpec = _buildProjectTaskRow(
            context,
            item.task,
            widget.selectionState,
            onLongPressOverride: widget.selectionState.isSelectionMode
                ? null
                : () => _showActionSheet(item),
          );
          final row = TasklyFeedRenderer.buildRow(
            rowSpec,
            context: context,
          );

          return Container(
            key: ValueKey('project-next-action-${item.task.id}'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: TasklyTokens.of(context).spaceXs,
                    top: TasklyTokens.of(context).spaceLg,
                  ),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(width: TasklyTokens.of(context).spaceSm),
                Expanded(child: row),
              ],
            ),
          );
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TasklyFeedRenderer.buildRow(header, context: context),
        TasklyFeedRenderer.buildRow(pickerRow, context: context),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (rows.isEmpty)
          TasklyFeedRenderer.buildRow(
            TasklyRowSpec.subheader(
              key: 'project-next-actions-empty',
              title: l10n.projectNextActionsEmptyLabel,
            ),
            context: context,
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _handleReorder,
            children: rows,
          ),
      ],
    );
  }
}

class _NextActionEntry {
  const _NextActionEntry({
    required this.action,
    required this.task,
  });

  final ProjectNextAction action;
  final Task task;
}

TasklyRowSpec _buildProjectTaskRow(
  BuildContext context,
  Task task,
  SelectionState selectionState, {
  List<TasklyBadgeData> badges = const [],
  VoidCallback? onTapOverride,
  VoidCallback? onLongPressOverride,
}) {
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
    badges: badges,
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
        if (onTapOverride != null) {
          onTapOverride();
        } else {
          buildTaskOpenEditorHandler(context, task: task)();
        }
      },
      onLongPress: () {
        if (onLongPressOverride != null) {
          onLongPressOverride();
        } else {
          selection.enterSelectionMode(initialSelection: key);
        }
      },
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
