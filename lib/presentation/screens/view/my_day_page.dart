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
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_overflow_menu.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_bloc/presentation/shared/widgets/filter_sort_sheet.dart';
import 'package:taskly_bloc/presentation/shared/widgets/display_density_sheet.dart';
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
import 'package:taskly_bloc/presentation/shared/bloc/display_density_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

enum _MyDayMode { execute, plan }

enum _MyDayMenuAction {
  density,
  selectMultiple,
}

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  _MyDayMode _mode = _MyDayMode.execute;
  bool _showCompleted = true;
  _MyDayTaskSortOrder _sortOrder = _MyDayTaskSortOrder.defaultOrder;

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
      includeInMyDayDefault: true,
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

  Future<void> _showFilterSheet(BuildContext context) async {
    final l10n = context.l10n;
    await showFilterSortSheet(
      context: context,
      sortGroups: [
        FilterSortRadioGroup(
          title: l10n.sortLabel,
          options: [
            for (final order in _MyDayTaskSortOrder.values)
              FilterSortRadioOption(
                value: order,
                label: order.label(l10n),
              ),
          ],
          selectedValue: _sortOrder,
          onSelected: (value) => setState(
            () => _sortOrder = value as _MyDayTaskSortOrder,
          ),
        ),
      ],
      toggles: [
        FilterSortToggle(
          title: l10n.showCompletedLabel,
          value: _showCompleted,
          onChanged: (_) => _toggleShowCompleted(),
        ),
      ],
    );
  }

  Future<void> _showDensitySheet(BuildContext context) async {
    final density = context.read<DisplayDensityBloc>().state.density;
    await showDisplayDensitySheet(
      context: context,
      density: density,
      onChanged: (next) {
        context.read<DisplayDensityBloc>().add(DisplayDensitySet(next));
      },
    );
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
            projectAnchorStateRepository: context
                .read<ProjectAnchorStateRepositoryContract>(),
            taskWriteService: context.read<TaskWriteService>(),
            routineWriteService: context.read<RoutineWriteService>(),
            dayKeyService: context.read<HomeDayKeyService>(),
            temporalTriggerService: context.read<TemporalTriggerService>(),
            nowService: context.read<NowService>(),
            valueRatingsRepository: context
                .read<ValueRatingsRepositoryContract>(),
            demoModeService: context.read<DemoModeService>(),
            demoDataProvider: context.read<DemoDataProvider>(),
          ),
        ),
        BlocProvider(
          create: (context) => DisplayDensityBloc(
            settingsRepository: context.read<SettingsRepositoryContract>(),
            pageKey: PageKey.myDay,
            defaultDensity: DisplayDensity.compact,
          )..add(const DisplayDensityStarted()),
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
                      sortOrder: _sortOrder,
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
                              tooltip: context.l10n.filterSortTooltip,
                              icon: const Icon(Icons.tune_rounded),
                              onPressed: () => _showFilterSheet(context),
                            ),
                            TasklyOverflowMenuButton<_MyDayMenuAction>(
                              tooltip: context.l10n.moreLabel,
                              itemsBuilder: (context) => [
                                PopupMenuItem(
                                  value: _MyDayMenuAction.density,
                                  child: TasklyMenuItemLabel(
                                    context.l10n.displayDensityTitle,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _MyDayMenuAction.selectMultiple,
                                  child: TasklyMenuItemLabel(
                                    context.l10n.selectMultipleLabel,
                                  ),
                                ),
                              ],
                              onSelected: (action) {
                                switch (action) {
                                  case _MyDayMenuAction.density:
                                    _showDensitySheet(context);
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
    required this.sortOrder,
  });

  final DateTime today;
  final DateTime dayKeyUtc;
  final VoidCallback onOpenPlan;
  final bool showCompleted;
  final _MyDayTaskSortOrder sortOrder;

  @override
  Widget build(BuildContext context) {
    final density = context.select(
      (DisplayDensityBloc bloc) => bloc.state.density,
    );
    final settings = context.watch<GlobalSettingsBloc>().state.settings;
    final nowLocal = context.read<NowService>().nowLocal();
    final reviewReady = isWeeklyReviewReady(settings, nowLocal);
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'my_day',
      iconName: null,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('EEE, d MMM', locale).format(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<MyDayBloc, MyDayState>(
          builder: (context, state) {
            final (plannedCount, completedCount) = switch (state) {
              MyDayLoaded(
                :final plannedItems,
                :final ritualStatus,
              )
                  when ritualStatus.hasAnyPick =>
                (
                  plannedItems.length,
                  plannedItems.where((item) => item.completed).length,
                ),
              _ => (null, null),
            };
            final hasPlan = switch (state) {
              MyDayLoaded(:final ritualStatus) => ritualStatus.hasAnyPick,
              _ => false,
            };

            return _MyDaySummaryHeader(
              icon: iconSet.selectedIcon,
              title: context.l10n.myDayTitle,
              dateLabel: dateLabel,
              plannedCount: plannedCount,
              completedCount: completedCount,
              hasPlan: hasPlan,
              onEditPlan: onOpenPlan,
            );
          },
        ),
        Expanded(
          child: BlocBuilder<MyDayBloc, MyDayState>(
            builder: (context, state) {
              return switch (state) {
                MyDayLoading() => Center(
                  child: AppLoadingContent(
                    title: context.l10n.myDayLoadingTitle,
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
                      _MyDayTaskList(
                        today: today,
                        dayKeyUtc: dayKeyUtc,
                        plannedItems: plannedItems,
                        tasks: state.tasks,
                        showCompleted: showCompleted,
                        onOpenPlan: onOpenPlan,
                        density: density,
                        sortOrder: sortOrder,
                        emptyStateIcon: iconSet.selectedIcon,
                        hasPlan: state.ritualStatus.hasAnyPick,
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

class _MyDaySummaryHeader extends StatelessWidget {
  const _MyDaySummaryHeader({
    required this.icon,
    required this.title,
    required this.dateLabel,
    required this.plannedCount,
    required this.completedCount,
    required this.hasPlan,
    required this.onEditPlan,
  });

  final IconData icon;
  final String title;
  final String dateLabel;
  final int? plannedCount;
  final int? completedCount;
  final bool hasPlan;
  final VoidCallback? onEditPlan;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final planned = plannedCount;
    final completed = completedCount;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: scheme.primary,
                size: tokens.spaceLg3,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasPlan && onEditPlan != null)
                TextButton(
                  key: GuidedTourAnchors.myDayPlanButton,
                  onPressed: onEditPlan,
                  style: TextButton.styleFrom(
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(l10n.myDayUpdatePlanTitle),
                ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceXs2,
            children: [
              _MyDaySummaryPill(label: dateLabel),
              if (planned != null)
                _MyDaySummaryPill(
                  label: context.l10n.myDayPlannedCountLabel(planned),
                ),
              if (completed != null)
                _MyDaySummaryPill(
                  label: context.l10n.myDayCompletedCountLabel(completed),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyDaySummaryPill extends StatelessWidget {
  const _MyDaySummaryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSm2,
          vertical: tokens.spaceXs2,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ),
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
    required this.density,
    required this.sortOrder,
    required this.emptyStateIcon,
    required this.hasPlan,
  });

  final DateTime today;
  final DateTime dayKeyUtc;
  final List<MyDayPlannedItem> plannedItems;
  final List<Task> tasks;
  final bool showCompleted;
  final VoidCallback onOpenPlan;
  final DisplayDensity density;
  final _MyDayTaskSortOrder sortOrder;
  final IconData emptyStateIcon;
  final bool hasPlan;

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
      density: widget.density,
    );
    final completedRoutineRows = widget.showCompleted
        ? _buildRoutineRows(
            context,
            completedRoutineEntries,
            dayKeyUtc: widget.dayKeyUtc,
            density: widget.density,
          )
        : const <TasklyRowSpec>[];
    final routineRows = [...activeRoutineRows, ...completedRoutineRows];
    final activeTaskRows = _buildTaskRows(
      context,
      activeTaskEntriesCombined,
      todayDate: todayDate,
      density: widget.density,
      sortOrder: widget.sortOrder,
    );
    final completedTaskRows = widget.showCompleted
        ? _buildTaskRows(
            context,
            completedTaskEntriesCombined,
            todayDate: todayDate,
            density: widget.density,
            sortOrder: widget.sortOrder,
          )
        : const <TasklyRowSpec>[];

    final taskRows = [...activeTaskRows, ...completedTaskRows];
    if (routineRows.isEmpty && taskRows.isEmpty) {
      final hasTasks = widget.tasks.isNotEmpty;
      final hasPlan = widget.hasPlan;

      final (title, description) = hasPlan
          ? (
              l10n.myDayAllClearTitle,
              l10n.myDayAllClearSubtitle,
            )
          : hasTasks
          ? (
              l10n.myDayNoPlanTitle,
              l10n.myDayNoPlanSubtitle,
            )
          : (
              l10n.myDayNoTasksTitle,
              l10n.myDayNoTasksSubtitle,
            );

      final String? actionLabel;
      final VoidCallback? onAction;
      if (hasPlan) {
        actionLabel = l10n.myDayUpdatePlanTitle;
        onAction = widget.onOpenPlan;
      } else if (hasTasks) {
        actionLabel = l10n.myDayPlanMyDayTitle;
        onAction = widget.onOpenPlan;
      } else {
        actionLabel = l10n.projectsTitle;
        onAction = () => Routing.toScreenKey(context, 'projects');
      }

      return _MyDayEmptyState(
        icon: widget.emptyStateIcon,
        title: title,
        description: description,
        actionLabel: actionLabel,
        onAction: onAction,
        showPlanAnchor: !hasPlan && hasTasks,
      );
    }

    final hasActiveRows =
        activeRoutineRows.isNotEmpty || activeTaskRows.isNotEmpty;
    final hasCompletedRows =
        completedRoutineRows.isNotEmpty || completedTaskRows.isNotEmpty;

    final rows = <TasklyRowSpec>[
      ...activeRoutineRows,
      if (activeRoutineRows.isNotEmpty && activeTaskRows.isNotEmpty)
        TasklyRowSpec.divider(key: 'myday-list-divider-active'),
      ...activeTaskRows,
      if (hasActiveRows && hasCompletedRows)
        TasklyRowSpec.divider(key: 'myday-list-divider-completed'),
      ...completedRoutineRows,
      ...completedTaskRows,
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
  required DisplayDensity density,
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
        style: density == DisplayDensity.compact
            ? const TasklyRoutineRowStyle.compact()
            : const TasklyRoutineRowStyle.standard(),
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
  required DisplayDensity density,
  required _MyDayTaskSortOrder sortOrder,
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
  final sortedTasks = _sortMyDayTasks(
    taskEntries
        .map((entry) => entry.item.task)
        .whereType<Task>()
        .toList(growable: false),
    order: sortOrder,
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
        density: density,
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
              context.l10n.myDayLoadFailedTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              context.l10n.myDayLoadFailedSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.retryButton),
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
                  l10n.weeklyReviewReadyBanner,
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
                child: Text(context.l10n.reviewExcludedTasks),
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
  required TasklyRoutineRowStyle style,
  int depthOffset = 0,
}) {
  final data = buildRoutineRowData(
    context,
    routine: routine,
    snapshot: snapshot,
    completed: completed,
    highlightCompleted: false,
    showProgress: true,
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
    style: style,
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
  required DisplayDensity density,
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

  final useCompactDensity = density == DisplayDensity.compact;
  final labels = useCompactDensity
      ? _compactDateLabels(
          context,
          task: task,
          today: todayDate,
        )
      : (startLabel: null, deadlineLabel: null);

  final data = buildTaskRowData(
    context,
    task: task,
    tileCapabilities: tileCapabilities,
    overrideStartDateLabel: labels.startLabel,
    overrideDeadlineDateLabel: labels.deadlineLabel,
    overrideIsOverdue: _isOverdue(task, todayDate),
    overrideIsDueToday: _isDueToday(task, todayDate),
  );

  return TasklyRowSpec.task(
    key: 'myday-accepted-${task.id}',
    data: data,
    depth: depthOffset,
    style: selectionMode
        ? (useCompactDensity
              ? TasklyTaskRowStyle.bulkSelectionCompact(selected: isSelected)
              : TasklyTaskRowStyle.bulkSelection(selected: isSelected))
        : (useCompactDensity
              ? const TasklyTaskRowStyle.compact()
              : const TasklyTaskRowStyle.standard()),
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

class _MyDayEmptyState extends StatelessWidget {
  const _MyDayEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.showPlanAnchor,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showPlanAnchor;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSize = tokens.spaceLg3 * 1.6;
    final iconContainerSize = tokens.spaceLg3 * 3;

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceXl,
          tokens.spaceLg,
          tokens.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: scheme.primary,
              ),
            ),
            SizedBox(height: tokens.spaceLg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: tokens.spaceLg),
              FilledButton(
                key: showPlanAnchor ? GuidedTourAnchors.myDayPlanButton : null,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

({String? startLabel, String? deadlineLabel}) _compactDateLabels(
  BuildContext context, {
  required Task task,
  required DateTime today,
}) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  final dateOnlyDeadline = dateOnlyOrNull(deadline);
  String? deadlineLabel;
  if (dateOnlyDeadline != null) {
    if (dateOnlyDeadline.isBefore(today)) {
      deadlineLabel = context.l10n.overdueLabel;
    } else if (dateOnlyDeadline.isAtSameMomentAs(today)) {
      deadlineLabel = context.l10n.dueTodayLabel;
    } else {
      deadlineLabel = MaterialLocalizations.of(context).formatMediumDate(
        deadline!,
      );
    }
  }

  final start = task.occurrence?.date ?? task.startDate;
  final startDay = dateOnlyOrNull(start);
  final startLabel = startDay == null || startDay.isBefore(today)
      ? null
      : MaterialLocalizations.of(context).formatMediumDate(start!);

  return (startLabel: startLabel, deadlineLabel: deadlineLabel);
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

enum _MyDayTaskSortOrder {
  defaultOrder,
  recentlyUpdated,
  alphabetical,
  priority,
  dueDate,
}

extension _MyDayTaskSortOrderLabels on _MyDayTaskSortOrder {
  String label(AppLocalizations l10n) {
    return switch (this) {
      _MyDayTaskSortOrder.defaultOrder => l10n.sortDefault,
      _MyDayTaskSortOrder.recentlyUpdated => l10n.sortRecentlyUpdated,
      _MyDayTaskSortOrder.alphabetical => l10n.sortAlphabetical,
      _MyDayTaskSortOrder.priority => l10n.sortPriority,
      _MyDayTaskSortOrder.dueDate => l10n.sortDueDate,
    };
  }
}

List<Task> _sortMyDayTasks(
  List<Task> tasks, {
  required _MyDayTaskSortOrder order,
  required DateTime today,
}) {
  if (order == _MyDayTaskSortOrder.defaultOrder) {
    return sortTasksByDeadlineThenStartThenPriorityThenName(
      tasks,
      today: today,
    );
  }

  int byName(Task a, Task b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int byUpdated(Task a, Task b) {
    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) return byUpdated;
    return byName(a, b);
  }

  int byPriority(Task a, Task b) {
    final aPriority = a.priority ?? 999;
    final bPriority = b.priority ?? 999;
    final byPriority = aPriority.compareTo(bPriority);
    if (byPriority != 0) return byPriority;
    return byName(a, b);
  }

  int byDueDate(Task a, Task b) {
    final aDate = a.occurrence?.deadline ?? a.deadlineDate;
    final bDate = b.occurrence?.deadline ?? b.deadlineDate;
    if (aDate != null && bDate != null) {
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
    } else if (aDate != null || bDate != null) {
      return aDate != null ? -1 : 1;
    }
    return byName(a, b);
  }

  final sorted = tasks.toList(growable: false);
  sorted.sort(
    switch (order) {
      _MyDayTaskSortOrder.recentlyUpdated => byUpdated,
      _MyDayTaskSortOrder.alphabetical => byName,
      _MyDayTaskSortOrder.priority => byPriority,
      _MyDayTaskSortOrder.dueDate => byDueDate,
      _MyDayTaskSortOrder.defaultOrder => byName,
    },
  );
  return sorted;
}
