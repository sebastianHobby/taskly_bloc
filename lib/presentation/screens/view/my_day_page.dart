import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/utils/weekly_review_schedule.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_gate_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/screens/view/plan_my_day_page.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_values_gate.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

enum _MyDayMode { execute, plan }

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  _MyDayMode _mode = _MyDayMode.execute;

  Future<void> _openNewTaskEditor(
    BuildContext context, {
    required DateTime defaultDay,
  }) {
    return context.read<EditorLauncher>().openTaskEditor(
      context,
      taskId: null,
      showDragHandle: true,
      defaultStartDate: defaultDay,
      defaultDeadlineDate: defaultDay,
    );
  }

  Future<void> _openNewProjectEditor(BuildContext context) {
    return context.read<EditorLauncher>().openProjectEditor(
      context,
      projectId: null,
      showDragHandle: true,
    );
  }

  void _enterPlanMode(BuildContext context) {
    context.read<PlanMyDayBloc>().add(const PlanMyDayStarted());

    setState(() {
      _mode = _MyDayMode.plan;
    });
  }

  void _exitPlanMode() {
    setState(() {
      _mode = _MyDayMode.execute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayKeyUtc = context.read<HomeDayService>().todayDayKeyUtc();
    final today = dayKeyUtc.toLocal();
    final tokens = TasklyTokens.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(
          create: (context) => MyDayGateBloc(
            queryService: context.read<MyDayGateQueryService>(),
          ),
        ),
        BlocProvider<MyDayBloc>(
          create: (context) => MyDayBloc(
            queryService: context.read<MyDaySessionQueryService>(),
            routineWriteService: context.read<RoutineWriteService>(),
            nowService: context.read<NowService>(),
          ),
        ),
        BlocProvider<PlanMyDayBloc>(
          create: (context) => PlanMyDayBloc(
            settingsRepository: context.read<SettingsRepositoryContract>(),
            myDayRepository: context.read<MyDayRepositoryContract>(),
            taskSuggestionService: context.read<TaskSuggestionService>(),
            taskRepository: context.read<TaskRepositoryContract>(),
            routineRepository: context.read<RoutineRepositoryContract>(),
            taskWriteService: context.read<TaskWriteService>(),
            routineWriteService: context.read<RoutineWriteService>(),
            dayKeyService: context.read<HomeDayKeyService>(),
            temporalTriggerService: context.read<TemporalTriggerService>(),
            nowService: context.read<NowService>(),
          ),
        ),
        BlocProvider(create: (_) => SelectionBloc()),
      ],
      child: BlocBuilder<PlanMyDayBloc, PlanMyDayState>(
        builder: (context, _) {
          if (_mode == _MyDayMode.plan) {
            return PlanMyDayPage(
              onCloseRequested: _exitPlanMode,
            );
          }

          return BlocBuilder<SelectionBloc, SelectionState>(
            builder: (context, selectionState) {
              final gateBody = BlocBuilder<MyDayGateBloc, MyDayGateState>(
                builder: (context, gateState) {
                  if (gateState is MyDayGateLoaded &&
                      gateState.needsValuesSetup) {
                    return const MyDayValuesGate();
                  }
                  return _MyDayLoadedBody(
                    today: today,
                    dayKeyUtc: dayKeyUtc,
                    onOpenPlan: () => _enterPlanMode(context),
                  );
                },
              );

              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? SelectionAppBar(
                        baseTitle: context.l10n.myDayTitle,
                        onExit: () {},
                      )
                    : AppBar(
                        toolbarHeight: 56,
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.myDayTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            SizedBox(height: tokens.spaceXxs2),
                            Text(
                              context.l10n.myDaySubtitleChosenForToday,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            tooltip: context.l10n.settingsTitle,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () =>
                                Routing.toScreenKey(context, 'settings'),
                          ),
                        ],
                      ),
                floatingActionButton: selectionState.isSelectionMode
                    ? null
                    : EntityAddSpeedDial(
                        heroTag: 'add_speed_dial_my_day',
                        onCreateTask: () => _openNewTaskEditor(
                          context,
                          defaultDay: today,
                        ),
                        onCreateProject: () => _openNewProjectEditor(
                          context,
                        ),
                      ),
                body: gateBody,
              );
            },
          );
        },
      ),
    );
  }
}

class _MyDayLoadedBody extends StatelessWidget {
  const _MyDayLoadedBody({
    required this.today,
    required this.dayKeyUtc,
    required this.onOpenPlan,
  });

  final DateTime today;
  final DateTime dayKeyUtc;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsBloc>().state.settings;
    final nowLocal = context.read<NowService>().nowLocal();
    final reviewReady = isWeeklyReviewReady(settings, nowLocal);
    final showDueSoon = settings.myDayDueSoonEnabled;
    final showPlanned = settings.myDayShowAvailableToStart;

    return BlocBuilder<MyDayBloc, MyDayState>(
      builder: (context, state) {
        return switch (state) {
          MyDayLoading() => Center(
            child: AppLoadingContent(
              title: 'Preparing a calm list for today...',
              subtitle: '',
              icon: Icons.auto_awesome,
            ),
          ),
          MyDayError() => _MyDayErrorState(
            onRetry: () => context.read<MyDayBloc>().add(const MyDayStarted()),
          ),
          MyDayLoaded(
            :final plannedItems,
            :final pinnedTasks,
          ) =>
            SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  TasklyTokens.of(context).spaceLg,
                  TasklyTokens.of(context).spaceXs2,
                  TasklyTokens.of(context).spaceLg,
                  0,
                ),
                children: [
                  if (reviewReady) ...[
                    _WeeklyReviewBanner(
                      onReview: () => showWeeklyReviewModal(
                        context,
                        settings: settings,
                      ),
                      onSettings: () =>
                          Routing.toScreenKey(context, 'settings'),
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                  ],
                  _MyDayHeaderRow(
                    today: today,
                    showDueSoon: showDueSoon,
                    showPlanned: showPlanned,
                    onUpdatePlan: onOpenPlan,
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  _MyDayTaskList(
                    today: today,
                    dayKeyUtc: dayKeyUtc,
                    plannedItems: plannedItems,
                    pinnedTasks: pinnedTasks,
                  ),
                ],
              ),
            ),
        };
      },
    );
  }
}

class _MyDayHeaderRow extends StatelessWidget {
  const _MyDayHeaderRow({
    required this.today,
    required this.showDueSoon,
    required this.showPlanned,
    required this.onUpdatePlan,
  });

  final DateTime today;
  final bool showDueSoon;
  final bool showPlanned;
  final VoidCallback onUpdatePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('EEE, d MMM', locale).format(today);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                dateLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: onUpdatePlan,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: TasklyTokens.of(context).spaceLg,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.myDayUpdatePlanTitle),
            ),
          ],
        ),
      ],
    );
  }
}

class _MyDayTaskList extends StatefulWidget {
  const _MyDayTaskList({
    required this.today,
    required this.dayKeyUtc,
    required this.plannedItems,
    required this.pinnedTasks,
  });

  final DateTime today;
  final DateTime dayKeyUtc;
  final List<MyDayPlannedItem> plannedItems;
  final List<Task> pinnedTasks;

  @override
  State<_MyDayTaskList> createState() => _MyDayTaskListState();
}

class _MyDayTaskListState extends State<_MyDayTaskList> {
  var _routinesCollapsed = false;
  var _tasksCollapsed = false;
  var _completedCollapsed = true;

  @override
  Widget build(BuildContext context) {
    final selection = context.read<SelectionBloc>();
    final todayDate = dateOnly(widget.today);

    final pickedTaskIds = widget.plannedItems
        .where((item) => item.type == MyDayPlannedItemType.task)
        .map((item) => item.id)
        .toSet();

    final plannedEntries = widget.plannedItems
        .map((item) => _MyDayListEntry(item: item))
        .toList(growable: false);

    final pinnedEntries = widget.pinnedTasks
        .where((task) => !pickedTaskIds.contains(task.id))
        .map(
          (task) => _MyDayListEntry(
            item: MyDayPlannedItem.task(
              task: task,
              bucket: my_day.MyDayPickBucket.manual,
              sortIndex: -1,
              qualifyingValueId: task.effectivePrimaryValueId,
            ),
          ),
        )
        .toList(growable: false);

    final routineEntries = plannedEntries
        .where((entry) => entry.item.type == MyDayPlannedItemType.routine)
        .toList(growable: false);
    final completedRoutineEntries = routineEntries
        .where((entry) => entry.item.completed)
        .toList(
          growable: false,
        );
    final activeRoutineEntries = routineEntries
        .where((entry) => !entry.item.completed)
        .toList(
          growable: false,
        );

    final plannedTaskEntries = plannedEntries.where(
      (entry) => entry.item.type == MyDayPlannedItemType.task,
    );
    final completedTaskEntries = plannedTaskEntries
        .where((entry) => entry.item.completed)
        .toList(
          growable: false,
        );
    final activeTaskEntries = plannedTaskEntries
        .where((entry) => !entry.item.completed)
        .toList(
          growable: false,
        );

    final taskEntries = [...pinnedEntries, ...activeTaskEntries];

    final hasCompleted =
        completedRoutineEntries.isNotEmpty || completedTaskEntries.isNotEmpty;
    if (routineEntries.isEmpty && taskEntries.isEmpty && !hasCompleted) {
      return TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.check_circle_outline,
            title: 'All clear for today.',
            description:
                'Nothing scheduled right now. If you want, you can add something small.',
          ),
        ),
      );
    }

    final visibleTasks = taskEntries
        .map((entry) => entry.item.task)
        .whereType<Task>()
        .toList(growable: false);
    _registerVisibleTasks(selection, visibleTasks);

    final tokens = TasklyTokens.of(context);
    final routineRows = _buildRoutineRows(
      context,
      activeRoutineEntries,
      dayKeyUtc: widget.dayKeyUtc,
    );
    final taskRows = _buildTaskRows(
      context,
      taskEntries,
      todayDate: todayDate,
    );
    final completedRows = _buildCompletedRows(
      context,
      completedRoutineEntries: completedRoutineEntries,
      completedTaskEntries: completedTaskEntries,
      dayKeyUtc: widget.dayKeyUtc,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MyDayCollapsibleSection(
          title: 'Routines',
          count: routineRows.length,
          isCollapsed: _routinesCollapsed,
          onToggle: () => setState(
            () => _routinesCollapsed = !_routinesCollapsed,
          ),
          child: _buildSectionBody(
            context,
            id: 'myday-execute-routines',
            rows: routineRows,
            emptyLabel: 'Your routine list is clear today.',
          ),
        ),
        SizedBox(height: tokens.spaceSm2),
        _MyDayCollapsibleSection(
          title: 'Tasks',
          count: taskRows.length,
          isCollapsed: _tasksCollapsed,
          onToggle: () => setState(
            () => _tasksCollapsed = !_tasksCollapsed,
          ),
          child: _buildSectionBody(
            context,
            id: 'myday-execute-tasks',
            rows: taskRows,
            emptyLabel: 'Your task list is clear.',
          ),
        ),
        if (completedRows.isNotEmpty) ...[
          SizedBox(height: tokens.spaceSm2),
          _MyDayCollapsibleSection(
            title: 'Completed',
            count: completedRows.length,
            isCollapsed: _completedCollapsed,
            onToggle: () => setState(
              () => _completedCollapsed = !_completedCollapsed,
            ),
            child: _buildSectionBody(
              context,
              id: 'myday-execute-completed',
              rows: completedRows,
              emptyLabel: 'No completed items yet.',
            ),
          ),
        ],
      ],
    );
  }
}

class _MyDayCollapsibleSection extends StatelessWidget {
  const _MyDayCollapsibleSection({
    required this.title,
    required this.count,
    required this.isCollapsed,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final int count;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    );
    final countStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceMd,
                tokens.spaceSm2,
                tokens.spaceMd,
                tokens.spaceSm2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: titleStyle),
                  ),
                  Text('$count', style: countStyle),
                  SizedBox(width: tokens.spaceXs2),
                  Icon(
                    isCollapsed
                        ? Icons.expand_more_rounded
                        : Icons.expand_less_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceSm,
                tokens.spaceSm,
                tokens.spaceSm,
                tokens.spaceSm,
              ),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

List<TasklyRowSpec> _buildRoutineRows(
  BuildContext context,
  List<_MyDayListEntry> entries, {
  required DateTime dayKeyUtc,
}) {
  final routineEntries = entries
      .where((entry) => entry.item.type == MyDayPlannedItemType.routine)
      .toList(growable: false);
  routineEntries.sort((a, b) {
    final routineA = a.item.routine;
    final routineB = b.item.routine;
    final scheduledA = routineA?.routineType == RoutineType.weeklyFixed;
    final scheduledB = routineB?.routineType == RoutineType.weeklyFixed;
    if (scheduledA != scheduledB) return scheduledA ? -1 : 1;
    final bySortIndex = a.item.sortIndex.compareTo(b.item.sortIndex);
    if (bySortIndex != 0) return bySortIndex;
    final nameA = routineA?.name ?? '';
    final nameB = routineB?.name ?? '';
    return nameA.compareTo(nameB);
  });

  final rows = <TasklyRowSpec>[];
  for (final entry in routineEntries) {
    final item = entry.item;
    final routine = item.routine;
    final snapshot = item.routineSnapshot;
    if (routine == null || snapshot == null) continue;
    rows.add(
      _buildRoutineRow(
        context,
        routine: routine,
        snapshot: snapshot,
        completed: item.completed,
        dayKeyUtc: dayKeyUtc,
        completionsInPeriod: item.completionsInPeriod,
        depthOffset: 0,
      ),
    );
  }

  return rows;
}

List<TasklyRowSpec> _buildTaskRows(
  BuildContext context,
  List<_MyDayListEntry> entries, {
  required DateTime todayDate,
}) {
  final groups = _groupEntriesByValue(entries);
  final rows = <TasklyRowSpec>[];

  for (final group in groups) {
    final taskEntries = group.entries
        .where((entry) => entry.item.type == MyDayPlannedItemType.task)
        .toList(growable: false);

    final taskEntriesById = {
      for (final entry in taskEntries)
        if (entry.item.task != null) entry.item.task!.id: entry,
    };
    final sortedTasks = sortTasksByDeadlineThenStartThenPriorityThenName(
      taskEntries
          .map((entry) => entry.item.task)
          .whereType<Task>()
          .toList(growable: false),
      today: todayDate,
    );
    final sortedTaskEntries = [
      for (final task in sortedTasks)
        if (taskEntriesById[task.id] != null) taskEntriesById[task.id]!,
    ];

    for (final entry in sortedTaskEntries) {
      final item = entry.item;
      final task = item.task;
      if (task == null) continue;
      rows.add(
        _buildTaskRowSpec(
          context,
          task,
          depthOffset: 0,
        ),
      );
    }
  }

  return rows;
}

List<TasklyRowSpec> _buildCompletedRows(
  BuildContext context, {
  required List<_MyDayListEntry> completedRoutineEntries,
  required List<_MyDayListEntry> completedTaskEntries,
  required DateTime dayKeyUtc,
}) {
  final routineRows = _buildRoutineRows(
    context,
    completedRoutineEntries,
    dayKeyUtc: dayKeyUtc,
  );

  final taskRows = _buildCompletedTaskRows(
    context,
    completedTaskEntries,
  );

  return [...routineRows, ...taskRows];
}

List<TasklyRowSpec> _buildCompletedTaskRows(
  BuildContext context,
  List<_MyDayListEntry> entries,
) {
  final completedTaskEntries =
      entries
          .where((entry) => entry.item.type == MyDayPlannedItemType.task)
          .toList(growable: false)
        ..sort((a, b) => a.item.sortIndex.compareTo(b.item.sortIndex));

  final rows = <TasklyRowSpec>[];
  for (final entry in completedTaskEntries) {
    final task = entry.item.task;
    if (task == null) continue;
    rows.add(
      _buildTaskRowSpec(
        context,
        task,
        depthOffset: 0,
      ),
    );
  }

  return rows;
}

Widget _buildSectionBody(
  BuildContext context, {
  required String id,
  required List<TasklyRowSpec> rows,
  required String emptyLabel,
}) {
  if (rows.isEmpty) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
      child: Text(
        emptyLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  return TasklyFeedRenderer.buildSection(
    TasklySectionSpec.standardList(
      id: id,
      rows: rows,
    ),
  );
}

List<_MyDayValueGroup> _groupEntriesByValue(List<_MyDayListEntry> entries) {
  final valueGroups = <String, _MyDayValueGroup>{};

  void ensureGroup(String key, Value? value) {
    valueGroups.putIfAbsent(
      key,
      () => _MyDayValueGroup(valueId: value?.id, value: value),
    );
  }

  for (final entry in entries) {
    final item = entry.item;
    final value = item.type == MyDayPlannedItemType.task
        ? item.task?.effectivePrimaryValue
        : item.routine?.value;
    final key = _myDayValueKey(value?.id);
    ensureGroup(key, value);
    valueGroups[key]!.entries.add(entry);
  }

  final groups = valueGroups.values.toList(growable: false)
    ..sort(_compareMyDayValueGroups);

  return groups;
}

class _MyDayErrorState extends StatelessWidget {
  const _MyDayErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load your list.",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              'Your tasks are safe. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyReviewBanner extends StatelessWidget {
  const _WeeklyReviewBanner({
    required this.onReview,
    required this.onSettings,
  });

  final VoidCallback onReview;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
        onTap: onReview,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceMd,
            TasklyTokens.of(context).spaceSm2,
            TasklyTokens.of(context).spaceSm2,
            TasklyTokens.of(context).spaceSm2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: scheme.primary,
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Expanded(
                child: Text(
                  'Weekly review is ready. Take 3 minutes to reset.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              TextButton(
                onPressed: onSettings,
                child: Text(l10n.settingsTitle),
              ),
              TextButton(
                onPressed: onReview,
                child: const Text('Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _registerVisibleTasks(
  SelectionBloc selection,
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

String _myDayValueKey(String? valueId) {
  final trimmed = valueId?.trim();
  if (trimmed == null || trimmed.isEmpty) return '_myday_value_none';
  return trimmed;
}

final class _MyDayListEntry {
  const _MyDayListEntry({
    required this.item,
  });

  final MyDayPlannedItem item;
}

class _MyDayValueGroup {
  _MyDayValueGroup({
    required this.valueId,
    required this.value,
  });

  final String? valueId;
  final Value? value;
  final List<_MyDayListEntry> entries = <_MyDayListEntry>[];
}

int _compareMyDayValueGroups(_MyDayValueGroup a, _MyDayValueGroup b) {
  final rankA = _valuePriorityRank(a.value?.priority ?? ValuePriority.medium);
  final rankB = _valuePriorityRank(b.value?.priority ?? ValuePriority.medium);
  if (rankA != rankB) return rankA.compareTo(rankB);
  final aName = (a.value?.name ?? '').toLowerCase();
  final bName = (b.value?.name ?? '').toLowerCase();
  return aName.compareTo(bName);
}

int _valuePriorityRank(ValuePriority priority) {
  return switch (priority) {
    ValuePriority.high => 0,
    ValuePriority.medium => 1,
    ValuePriority.low => 2,
  };
}

TasklyRowSpec _buildRoutineRow(
  BuildContext context, {
  required Routine routine,
  required RoutineCadenceSnapshot snapshot,
  required bool completed,
  required DateTime dayKeyUtc,
  required List<RoutineCompletion> completionsInPeriod,
  int depthOffset = 0,
}) {
  final data = buildRoutineRowData(
    context,
    routine: routine,
    snapshot: snapshot,
    completed: completed,
    highlightCompleted: false,
    showProgress:
        routine.routineType == RoutineType.weeklyFlexible ||
        routine.routineType == RoutineType.monthlyFlexible,
    showScheduleRow: routine.routineType == RoutineType.weeklyFixed,
    dayKeyUtc: dayKeyUtc,
    completionsInPeriod: completionsInPeriod,
    labels: buildRoutineExecutionLabels(
      context,
      completed: completed,
    ),
  );

  return TasklyRowSpec.routine(
    key: 'myday-routine-${routine.id}',
    data: data,
    depth: depthOffset,
    actions: TasklyRoutineRowActions(
      onTap: () => context.read<MyDayBloc>().add(
        MyDayRoutineCompletionToggled(
          routineId: routine.id,
          completedToday: completed,
          dayKeyUtc: dayKeyUtc,
        ),
      ),
      onPrimaryAction: () => context.read<MyDayBloc>().add(
        MyDayRoutineCompletionToggled(
          routineId: routine.id,
          completedToday: completed,
          dayKeyUtc: dayKeyUtc,
        ),
      ),
    ),
  );
}

TasklyRowSpec _buildTaskRowSpec(
  BuildContext context,
  Task task, {
  int depthOffset = 0,
}) {
  final selection = context.read<SelectionBloc>();
  final selectionMode = selection.isSelectionMode;
  final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
  final key = SelectionKey(
    entityType: EntityType.task,
    entityId: task.id,
  );
  final isSelected = selection.isSelected(key);

  final data = buildTaskRowData(
    context,
    task: task,
    tileCapabilities: tileCapabilities,
  );

  final labels = TasklyTaskRowLabels(
    pinnedSemanticLabel: context.l10n.pinnedSemanticLabel,
  );

  final updatedData = TasklyTaskRowData(
    id: data.id,
    title: data.title,
    completed: data.completed,
    meta: data.meta,
    leadingChip: data.leadingChip,
    secondaryChips: data.secondaryChips,
    deemphasized: data.deemphasized,
    checkboxSemanticLabel: data.checkboxSemanticLabel,
    labels: labels,
    pinned: task.isPinned,
  );

  return TasklyRowSpec.task(
    key: 'myday-accepted-${task.id}',
    data: updatedData,
    depth: depthOffset,
    style: selectionMode
        ? TasklyTaskRowStyle.bulkSelection(selected: isSelected)
        : const TasklyTaskRowStyle.standard(),
    actions: TasklyTaskRowActions(
      onTap: () {
        if (selection.shouldInterceptTapAsSelection()) {
          selection.handleEntityTap(key);
          return;
        }
        buildTaskOpenEditorHandler(context, task: task)();
      },
      onLongPress: () {
        selection.enterSelectionMode(initialSelection: key);
      },
      onToggleSelected: () => selection.toggleSelection(
        key,
        extendRange: false,
      ),
      onToggleCompletion: buildTaskToggleCompletionHandler(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
      ),
    ),
  );
}
