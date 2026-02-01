import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/review/utils/weekly_review_schedule.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_overflow_menu.dart';
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
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

enum _MyDayMode { execute, plan }

enum _MyDayMenuAction {
  showCompleted,
  selectMultiple,
}

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  _MyDayMode _mode = _MyDayMode.execute;
  bool _showCompleted = false;

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

  void _syncTourStep(BuildContext context, GuidedTourState state) {
    if (!state.active) return;
    final step = state.currentStep;
    if (step == null) return;

    if (step.id.startsWith('plan_my_day_')) {
      if (_mode != _MyDayMode.plan) {
        _enterPlanMode(context);
      }
      return;
    }

    if (_mode != _MyDayMode.execute &&
        (step.id == 'my_day_summary' || step.id == 'my_day_focus_list')) {
      _exitPlanMode();
    }
  }

  void _toggleShowCompleted() {
    setState(() => _showCompleted = !_showCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final dayKeyUtc = context.read<HomeDayService>().todayDayKeyUtc();
    final today = dayKeyUtc.toLocal();

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
            demoModeService: context.read<DemoModeService>(),
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
            demoModeService: context.read<DemoModeService>(),
            demoDataProvider: context.read<DemoDataProvider>(),
          ),
        ),
        BlocProvider(create: (_) => SelectionBloc()),
      ],
      child: BlocListener<GuidedTourBloc, GuidedTourState>(
        listenWhen: (previous, current) =>
            previous.currentIndex != current.currentIndex ||
            previous.active != current.active,
        listener: _syncTourStep,
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
                      showCompleted: _showCompleted,
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
                          actions: [
                            IconButton(
                              tooltip: context.l10n.settingsTitle,
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () =>
                                  Routing.toScreenKey(context, 'settings'),
                            ),
                            TasklyOverflowMenuButton<_MyDayMenuAction>(
                              tooltip: 'More',
                              itemsBuilder: (context) => [
                                CheckedPopupMenuItem(
                                  value: _MyDayMenuAction.showCompleted,
                                  checked: _showCompleted,
                                  child: const TasklyMenuItemLabel(
                                    'Show completed',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: _MyDayMenuAction.selectMultiple,
                                  child: TasklyMenuItemLabel('Select multiple'),
                                ),
                              ],
                              onSelected: (action) {
                                switch (action) {
                                  case _MyDayMenuAction.showCompleted:
                                    _toggleShowCompleted();
                                  case _MyDayMenuAction.selectMultiple:
                                    context
                                        .read<SelectionBloc>()
                                        .enterSelectionMode();
                                }
                              },
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
      ),
    );
  }
}

class _MyDayLoadedBody extends StatelessWidget {
  const _MyDayLoadedBody({
    required this.today,
    required this.dayKeyUtc,
    required this.onOpenPlan,
    required this.showCompleted,
  });

  final DateTime today;
  final DateTime dayKeyUtc;
  final VoidCallback onOpenPlan;
  final bool showCompleted;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsBloc>().state.settings;
    final nowLocal = context.read<NowService>().nowLocal();
    final reviewReady = isWeeklyReviewReady(settings, nowLocal);
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'my_day',
      iconName: null,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('EEE, d MMM', locale).format(today);
    final header = _buildGreetingHeader(
      context,
      icon: iconSet.selectedIcon,
      dateLabel: dateLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: BlocBuilder<MyDayBloc, MyDayState>(
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
                  onRetry: () =>
                      context.read<MyDayBloc>().add(const MyDayStarted()),
                ),
                MyDayLoaded(:final plannedItems) => SafeArea(
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
                        hasPlan: state.ritualStatus.hasAnyPick,
                        onUpdatePlan: onOpenPlan,
                      ),
                      SizedBox(height: TasklyTokens.of(context).spaceSm),
                      _MyDaySummaryStrip(
                        plannedCount: plannedItems.length,
                        routineCount: plannedItems
                            .where(
                              (item) =>
                                  item.type == MyDayPlannedItemType.routine,
                            )
                            .length,
                      ),
                      SizedBox(height: TasklyTokens.of(context).spaceSm),
                      _MyDayTaskList(
                        today: today,
                        dayKeyUtc: dayKeyUtc,
                        plannedItems: plannedItems,
                        tasks: state.tasks,
                        showCompleted: showCompleted,
                        onOpenPlan: onOpenPlan,
                      ),
                    ],
                  ),
                ),
              };
            },
          ),
        ),
      ],
    );
  }
}

Widget _buildGreetingHeader(
  BuildContext context, {
  required IconData icon,
  required String dateLabel,
}) {
  final l10n = context.l10n;
  final tagline = l10n.myDayHeaderTagline(dateLabel);

  Widget buildHeader(String? displayName) {
    final resolvedName = displayName?.trim();
    final greeting = resolvedName == null || resolvedName.isEmpty
        ? l10n.myDayGreetingWithoutName
        : l10n.myDayGreetingWithName(resolvedName);
    return _ScreenTitleHeader(
      icon: icon,
      greeting: greeting,
      tagline: tagline,
    );
  }

  final authBloc = _maybeReadAuthBloc(context);
  if (authBloc == null) {
    return buildHeader(null);
  }

  return BlocBuilder<AuthBloc, AppAuthState>(
    buildWhen: (previous, current) => previous.user != current.user,
    builder: (context, state) {
      return buildHeader(_displayNameFromAuthUser(state.user));
    },
  );
}

class _ScreenTitleHeader extends StatelessWidget {
  const _ScreenTitleHeader({
    required this.icon,
    required this.greeting,
    required this.tagline,
  });

  final IconData icon;
  final String greeting;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: tokens.spaceLg3),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  tagline,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _displayNameFromAuthUser(AuthUser? user) {
  final metadata = user?.metadata;
  final displayName =
      metadata?['display_name'] as String? ??
      metadata?['full_name'] as String? ??
      metadata?['name'] as String?;
  if (displayName == null) return null;
  final trimmed = displayName.trim();
  return trimmed.isEmpty ? null : trimmed;
}

AuthBloc? _maybeReadAuthBloc(BuildContext context) {
  try {
    return BlocProvider.of<AuthBloc>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

class _MyDayHeaderRow extends StatelessWidget {
  const _MyDayHeaderRow({
    required this.hasPlan,
    required this.onUpdatePlan,
  });

  final bool hasPlan;
  final VoidCallback onUpdatePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tokens = TasklyTokens.of(context);

    final button = hasPlan
        ? OutlinedButton(
            key: GuidedTourAnchors.myDayPlanButton,
            onPressed: onUpdatePlan,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.myDayUpdatePlanTitle),
          )
        : FilledButton(
            key: GuidedTourAnchors.myDayPlanButton,
            onPressed: onUpdatePlan,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.myDayPlanMyDayTitle),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            button,
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
    required this.tasks,
    required this.showCompleted,
    required this.onOpenPlan,
  });

  final DateTime today;
  final DateTime dayKeyUtc;
  final List<MyDayPlannedItem> plannedItems;
  final List<Task> tasks;
  final bool showCompleted;
  final VoidCallback onOpenPlan;

  @override
  State<_MyDayTaskList> createState() => _MyDayTaskListState();
}

class _MyDayTaskListState extends State<_MyDayTaskList> {
  @override
  Widget build(BuildContext context) {
    final selection = context.read<SelectionBloc>();
    final l10n = context.l10n;
    final todayDate = dateOnly(widget.today);

    final plannedEntries = widget.plannedItems
        .map((item) => _MyDayListEntry(item: item))
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

    final activeTaskEntriesCombined = activeTaskEntries;

    final completedTaskEntriesCombined = widget.showCompleted
        ? completedTaskEntries
        : const <_MyDayListEntry>[];

    final visibleTasks = [
      ...activeTaskEntriesCombined,
      if (widget.showCompleted) ...completedTaskEntriesCombined,
    ].map((entry) => entry.item.task).whereType<Task>().toList(growable: false);
    _registerVisibleTasks(selection, visibleTasks);

    final activeRoutineRows = _buildRoutineRows(
      context,
      activeRoutineEntries,
      dayKeyUtc: widget.dayKeyUtc,
    );
    final completedRoutineRows = widget.showCompleted
        ? _buildRoutineRows(
            context,
            completedRoutineEntries,
            dayKeyUtc: widget.dayKeyUtc,
          )
        : const <TasklyRowSpec>[];
    final routineRows = [...activeRoutineRows, ...completedRoutineRows];
    final activeTaskRows = _buildTaskRows(
      context,
      activeTaskEntriesCombined,
      todayDate: todayDate,
    );
    final completedTaskRows = widget.showCompleted
        ? _buildTaskRows(
            context,
            completedTaskEntriesCombined,
            todayDate: todayDate,
          )
        : const <TasklyRowSpec>[];

    final taskRows = [...activeTaskRows, ...completedTaskRows];
    if (routineRows.isEmpty && taskRows.isEmpty) {
      final hasTasks = widget.tasks.isNotEmpty;
      final emptyTitle = hasTasks ? 'No plan yet.' : 'All clear for today.';
      final emptyBody = hasTasks
          ? 'You have tasks ready to choose from.'
          : 'Add a task to get started.';
      final ctaLabel = hasTasks
          ? l10n.myDayPlanMyDayTitle
          : l10n.myDayAddTaskAction;

      return TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.check_circle_outline,
            title: emptyTitle,
            description: emptyBody,
            actionLabel: ctaLabel,
            onAction: () {
              if (hasTasks) {
                widget.onOpenPlan();
              } else {
                context.read<EditorLauncher>().openTaskEditor(
                  context,
                  taskId: null,
                  showDragHandle: true,
                );
              }
            },
          ),
        ),
      );
    }

    final rows = <TasklyRowSpec>[
      ...routineRows,
      if (routineRows.isNotEmpty && taskRows.isNotEmpty)
        TasklyRowSpec.divider(key: 'myday-list-divider'),
      ...taskRows,
    ];

    return TasklyFeedRenderer.buildSection(
      TasklySectionSpec.standardList(
        id: 'myday-execute-list',
        rows: rows,
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
  final rows = <TasklyRowSpec>[];

  final taskEntries = entries
      .where((entry) => entry.item.type == MyDayPlannedItemType.task)
      .toList(growable: false);
  if (taskEntries.isEmpty) return rows;

  final entriesById = {
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

  final sortedEntries = <_MyDayListEntry>[
    for (final task in sortedTasks)
      if (entriesById[task.id] != null) entriesById[task.id]!,
  ];

  for (final entry in sortedEntries) {
    final task = entry.item.task;
    if (task == null) continue;
    rows.add(
      _buildTaskRowSpec(
        context,
        task,
        todayDate: todayDate,
        depthOffset: 0,
      ),
    );
  }

  return rows;
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
            canCompleteSeries: task.isRepeating && !task.seriesEnded,
          ),
        )
        .toList(growable: false),
  );
}

final class _MyDayListEntry {
  const _MyDayListEntry({
    required this.item,
  });

  final MyDayPlannedItem item;
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
    showScheduleRow: false,
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
      onTap: () => Routing.toRoutineEdit(context, routine.id),
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
  required DateTime todayDate,
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
    overrideDeadlineDateLabel: _compactDueLabel(
      context,
      task: task,
      today: todayDate,
    ),
    overrideIsOverdue: _isOverdue(task, todayDate),
    overrideIsDueToday: _isDueToday(task, todayDate),
  );

  return TasklyRowSpec.task(
    key: 'myday-accepted-${task.id}',
    data: data,
    depth: depthOffset,
    style: selectionMode
        ? TasklyTaskRowStyle.bulkSelection(selected: isSelected)
        : const TasklyTaskRowStyle.compact(),
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

class _MyDaySummaryStrip extends StatelessWidget {
  const _MyDaySummaryStrip({
    required this.plannedCount,
    required this.routineCount,
  });

  final int plannedCount;
  final int routineCount;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget buildPill(String label) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceXs,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Wrap(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceXs2,
      children: [
        buildPill('Planned: $plannedCount'),
        buildPill('Routines: $routineCount'),
      ],
    );
  }
}

String? _compactDueLabel(
  BuildContext context, {
  required Task task,
  required DateTime today,
}) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  final dateOnlyDeadline = dateOnlyOrNull(deadline);
  if (dateOnlyDeadline == null) return null;
  if (dateOnlyDeadline.isBefore(today)) return 'Overdue';
  if (dateOnlyDeadline.isAtSameMomentAs(today)) return 'Due today';
  return MaterialLocalizations.of(context).formatMediumDate(deadline!);
}

bool _isOverdue(Task task, DateTime today) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  if (deadline == null) return false;
  final day = dateOnly(deadline);
  return day.isBefore(today);
}

bool _isDueToday(Task task, DateTime today) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  if (deadline == null) return false;
  final day = dateOnly(deadline);
  return day.isAtSameMomentAs(today);
}
