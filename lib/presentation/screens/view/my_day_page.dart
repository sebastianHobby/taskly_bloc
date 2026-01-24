import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_ritual_wizard_page.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

enum _MyDayMode { execute, plan }

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  _MyDayMode _mode = _MyDayMode.execute;
  MyDayRitualWizardInitialSection? _planInitialSection;

  Future<void> _openNewTaskEditor(
    BuildContext context, {
    required DateTime defaultDay,
  }) {
    return EditorLauncher.fromGetIt().openTaskEditor(
      context,
      taskId: null,
      showDragHandle: true,
      defaultStartDate: defaultDay,
      defaultDeadlineDate: defaultDay,
    );
  }

  Future<void> _openNewProjectEditor(BuildContext context) {
    return EditorLauncher.fromGetIt().openProjectEditor(
      context,
      projectId: null,
      showDragHandle: true,
    );
  }

  void _enterPlanMode(
    BuildContext context, {
    MyDayRitualWizardInitialSection? initialSection,
  }) {
    context.read<MyDayRitualBloc>().add(const MyDayRitualStarted());

    setState(() {
      _mode = _MyDayMode.plan;
      _planInitialSection = initialSection;
    });
  }

  void _exitPlanMode() {
    setState(() {
      _mode = _MyDayMode.execute;
      _planInitialSection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = getIt<HomeDayService>().todayDayKeyUtc().toLocal();

    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(create: (_) => getIt<MyDayGateBloc>()),
        BlocProvider<MyDayBloc>(create: (_) => getIt<MyDayBloc>()),
        BlocProvider<MyDayRitualBloc>(create: (_) => getIt<MyDayRitualBloc>()),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: BlocBuilder<MyDayRitualBloc, MyDayRitualState>(
        builder: (context, ritualState) {
          final needsRitual =
              ritualState is MyDayRitualReady && ritualState.needsRitual;

          final effectiveMode = needsRitual ? _MyDayMode.plan : _mode;

          if (effectiveMode == _MyDayMode.plan) {
            return MyDayRitualWizardPage(
              allowClose: !needsRitual,
              initialSection: _planInitialSection,
              onCloseRequested: _exitPlanMode,
            );
          }

          if (ritualState is MyDayRitualLoading) {
            return AppLoadingScreen(
              appBarTitle: context.l10n.myDayTitle,
              title: context.l10n.myDayPreparingTitle,
              subtitle: context.l10n.myDayPreparingSubtitle,
              icon: Icons.auto_awesome,
            );
          }

          return BlocBuilder<SelectionCubit, SelectionState>(
            builder: (context, selectionState) {
              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? SelectionAppBar(
                        baseTitle: context.l10n.myDayTitle,
                        onExit: () {},
                      )
                    : AppBar(
                        toolbarHeight: 56,
                        title: Text(
                          context.l10n.myDayTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        actions: TasklyAppBarActions.withAttentionBell(
                          context,
                          actions: const <Widget>[],
                        ),
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
                body: _MyDayLoadedBody(
                  today: today,
                  onOpenPlan: (initialSection) => _enterPlanMode(
                    context,
                    initialSection: initialSection,
                  ),
                ),
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
    required this.onOpenPlan,
  });

  final DateTime today;
  final void Function(MyDayRitualWizardInitialSection? initialSection)
  onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final ritualState = context.watch<MyDayRitualBloc>().state;
    const defaultShowAvailableToStart = true;
    final focusReasons = ritualState is MyDayRitualReady
        ? ritualState.curatedReasons
        : const <String, String>{};
    final dueWindowDays = ritualState is MyDayRitualReady
        ? ritualState.dueWindowDays
        : 7;
    final showAvailableToStart = ritualState is MyDayRitualReady
        ? ritualState.showAvailableToStart
        : defaultShowAvailableToStart;

    return BlocBuilder<MyDayBloc, MyDayState>(
      builder: (context, state) {
        return switch (state) {
          MyDayLoading() => Center(
            child: AppLoadingContent(
              title: context.l10n.myDayPreparingTitle,
              subtitle: context.l10n.myDayPreparingSubtitle,
              icon: Icons.auto_awesome,
            ),
          ),
          MyDayError(:final message) => Center(child: Text(message)),
          MyDayLoaded(
            :final acceptedDue,
            :final acceptedStarts,
            :final acceptedFocus,
            :final pinnedTasks,
            :final completedPicks,
            :final selectedTotalCount,
            :final todaySelectedTaskIds,
          ) =>
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MyDayHeaderRow(
                              today: today,
                              onUpdatePlan: () => onOpenPlan(null),
                            ),
                            const SizedBox(height: 12),
                            _MyDaySections(
                              today: today,
                              acceptedDue: acceptedDue,
                              acceptedStarts: acceptedStarts,
                              acceptedFocus: acceptedFocus,
                              pinnedTasks: pinnedTasks,
                              completedPicks: completedPicks,
                              todaySelectedTaskIds: todaySelectedTaskIds,
                              focusReasons: focusReasons,
                              dueWindowDays: dueWindowDays,
                              showAvailableToStart: showAvailableToStart,
                              showCompletionMessage:
                                  selectedTotalCount > 0 &&
                                  acceptedDue.isEmpty &&
                                  acceptedStarts.isEmpty &&
                                  acceptedFocus.isEmpty,
                              onAddOneMoreFocus: selectedTotalCount > 0
                                  ? () => _openRitualResume(
                                      context,
                                      initialSection:
                                          MyDayRitualWizardInitialSection
                                              .suggested,
                                    )
                                  : null,
                              onWhyThese: () => _openRitualResume(
                                context,
                                initialSection:
                                    MyDayRitualWizardInitialSection.suggested,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        };
      },
    );
  }

  void _openRitualResume(
    BuildContext context, {
    MyDayRitualWizardInitialSection? initialSection,
  }) {
    onOpenPlan(initialSection);
  }
}

class _MyDayHeaderRow extends StatelessWidget {
  const _MyDayHeaderRow({
    required this.today,
    required this.onUpdatePlan,
  });

  final DateTime today;
  final VoidCallback onUpdatePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('EEE, MMM d', locale).format(today);

    return Row(
      children: [
        Expanded(
          child: Text(
            dateLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        FilledButton.tonal(
          onPressed: onUpdatePlan,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primaryContainer.withOpacity(0.6),
            foregroundColor: cs.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(context.l10n.myDayUpdatePlanTitle),
        ),
      ],
    );
  }
}

class _MyDaySections extends StatefulWidget {
  const _MyDaySections({
    required this.today,
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    required this.pinnedTasks,
    required this.completedPicks,
    required this.todaySelectedTaskIds,
    required this.focusReasons,
    required this.dueWindowDays,
    required this.showAvailableToStart,
    required this.showCompletionMessage,
    required this.onAddOneMoreFocus,
    required this.onWhyThese,
  });

  final DateTime today;
  final List<Task> acceptedDue;
  final List<Task> acceptedStarts;
  final List<Task> acceptedFocus;
  final List<Task> pinnedTasks;
  final List<Task> completedPicks;
  final Set<String> todaySelectedTaskIds;
  final Map<String, String> focusReasons;
  final int dueWindowDays;
  final bool showAvailableToStart;
  final bool showCompletionMessage;
  final VoidCallback? onAddOneMoreFocus;
  final VoidCallback? onWhyThese;

  @override
  State<_MyDaySections> createState() => _MyDaySectionsState();
}

class _MyDaySectionsState extends State<_MyDaySections> {
  static const _previewCount = 6;
  static const _duePreviewCount = 3;

  bool _valuesExpanded = true;
  bool _timeSensitiveExpanded = true;
  bool _completedExpanded = false;
  bool _pinnedExpanded = true;
  bool _dueExpanded = false;
  bool _startsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final selection = context.read<SelectionCubit>();

    final today = dateOnly(widget.today);
    final valuesSplit = _splitValuesAligned(
      tasks: widget.acceptedFocus,
      today: today,
      dueWindowDays: widget.dueWindowDays,
      showAvailableToStart: widget.showAvailableToStart,
    );
    final valuesDueSorted = sortTasksByDeadline(
      valuesSplit.due,
      today: today,
    );
    final valuesPlannedSorted = sortTasksByStartDate(valuesSplit.planned);
    final valuesAnytimeSorted = valuesSplit.anytime;
    final pinnedSorted = sortTasksByDeadlineThenStartThenName(
      widget.pinnedTasks,
      today: today,
    );
    final dueSorted = sortTasksByDeadline(
      widget.acceptedDue,
      today: today,
    );
    final startsSorted = sortTasksByStartDate(widget.acceptedStarts);
    final dueVisible = _dueExpanded
        ? dueSorted
        : dueSorted.take(_duePreviewCount).toList(growable: false);
    final startsVisible = _startsExpanded
        ? startsSorted
        : startsSorted.take(_previewCount).toList(growable: false);
    final completedVisible = widget.completedPicks;

    _registerVisibleTasks(selection, [
      ...pinnedSorted,
      ...valuesDueSorted,
      ...valuesPlannedSorted,
      ...valuesAnytimeSorted,
      ...dueVisible,
      ...startsVisible,
      ...completedVisible,
    ]);

    final valuesRows = _buildValuesRows(
      context,
      due: valuesDueSorted,
      planned: valuesPlannedSorted,
      anytime: valuesAnytimeSorted,
    );

    final pinnedRows = _buildPinnedRows(context, pinnedSorted);

    final dueRows = _buildRows(context, dueVisible);
    final startsRows = _buildRows(context, startsVisible);
    final completedRows = _buildRows(
      context,
      completedVisible,
      completedStatusLabel: l10n.projectCompletedLabel,
    );

    final dueFooter = _buildShowMoreFooter(
      context,
      expanded: _dueExpanded,
      remaining: widget.acceptedDue.length - dueVisible.length,
      total: widget.acceptedDue.length,
      onToggle: () => setState(() => _dueExpanded = !_dueExpanded),
      previewCount: _duePreviewCount,
    );

    final startsFooter = _buildShowMoreFooter(
      context,
      expanded: _startsExpanded,
      remaining: widget.acceptedStarts.length - startsVisible.length,
      total: widget.acceptedStarts.length,
      onToggle: () => setState(() => _startsExpanded = !_startsExpanded),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showCompletionMessage)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.myDayRitualAllSetTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.myDayRitualAllSetSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.onAddOneMoreFocus != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onAddOneMoreFocus,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.myDayRitualAddOneMoreFocus),
                    ),
                  ),
              ],
            ),
          ),
        if (widget.showCompletionMessage) const SizedBox(height: 12),
        TasklyMyDaySectionStack(
          pinned: pinnedRows.isEmpty
              ? null
              : TasklyMyDaySectionConfig(
                  title: l10n.pinnedTasksSection,
                  icon: null,
                  count: widget.pinnedTasks.length,
                  showCount: false,
                  expanded: _pinnedExpanded,
                  onToggleExpanded: () =>
                      setState(() => _pinnedExpanded = !_pinnedExpanded),
                  list: TasklyMyDaySectionList(
                    id: 'myday-execute-pinned',
                    rows: pinnedRows,
                  ),
                  emptyState: TasklyMyDayEmptyState(
                    title: l10n.pinnedTasksSection,
                    description: l10n.myDayPinnedSectionSubtitle,
                  ),
                  showEmpty: false,
                ),
          valuesAligned: TasklyMyDaySectionConfig(
            title: l10n.myDayWhatMattersSectionTitle,
            icon: Icons.eco_rounded,
            count: widget.acceptedFocus.length,
            showCount: false,
            expanded: _valuesExpanded,
            onToggleExpanded: () =>
                setState(() => _valuesExpanded = !_valuesExpanded),
            action: widget.onWhyThese == null
                ? null
                : TextButton(
                    onPressed: widget.onWhyThese,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    child: Text(l10n.myDayWhyTheseAction),
                  ),
            emptyState: TasklyMyDayEmptyState(
              title: l10n.myDayExecuteValuesEmptyTitle,
              description: l10n.myDayExecuteValuesEmptyBody,
            ),
            list: TasklyMyDaySectionList(
              id: 'myday-execute-values',
              rows: valuesRows,
            ),
          ),
          timeSensitive: TasklyMyDayTimeSensitiveConfig(
            title: l10n.myDayWhatsWaitingSectionTitle,
            icon: Icons.access_time_rounded,
            showCount: false,
            subtitle: l10n.myDayTimeSensitiveOutsideValuesSubtitle,
            expanded: _timeSensitiveExpanded,
            onToggleExpanded: () => setState(
              () => _timeSensitiveExpanded = !_timeSensitiveExpanded,
            ),
            due: TasklyMyDaySubsectionConfig(
              title: l10n.myDayDueSoonLabel,
              icon: Icons.warning_rounded,
              iconColor: cs.error,
              count: widget.acceptedDue.length,
              expanded: _dueExpanded,
              onToggleExpanded: () =>
                  setState(() => _dueExpanded = !_dueExpanded),
              list: TasklyMyDaySectionList(
                id: 'myday-execute-due',
                rows: dueRows,
                footer: dueFooter,
              ),
              emptyState: TasklyMyDayEmptyState(
                title: l10n.myDayExecuteDueEmptyTitle,
                description: l10n.myDayExecuteDueEmptyBody,
              ),
              showEmpty: false,
            ),
            planned: TasklyMyDaySubsectionConfig(
              title: l10n.myDayPlannedSectionTitle,
              icon: Icons.event_note_rounded,
              iconColor: cs.secondary,
              count: widget.acceptedStarts.length,
              expanded: _startsExpanded,
              onToggleExpanded: () =>
                  setState(() => _startsExpanded = !_startsExpanded),
              list: TasklyMyDaySectionList(
                id: 'myday-execute-planned',
                rows: startsRows,
                footer: startsFooter,
              ),
              emptyState: TasklyMyDayEmptyState(
                title: l10n.myDayExecutePlannedEmptyTitle,
                description: l10n.myDayExecutePlannedEmptyBody,
              ),
              showEmpty: false,
            ),
          ),
          completed: TasklyMyDaySectionConfig(
            title: l10n.myDayCompletedSectionTitle,
            icon: Icons.check_circle_outline,
            count: widget.completedPicks.length,
            showCount: false,
            expanded: _completedExpanded,
            onToggleExpanded: () =>
                setState(() => _completedExpanded = !_completedExpanded),
            list: TasklyMyDaySectionList(
              id: 'myday-execute-completed',
              rows: completedRows,
            ),
            emptyState: TasklyMyDayEmptyState(
              title: l10n.myDayCompletedSectionTitle,
              description: l10n.myDayCompletedSectionEmptyBody,
            ),
            showEmpty: false,
          ),
        ),
      ],
    );
  }

  List<TasklyRowSpec> _buildValuesRows(
    BuildContext context, {
    required List<Task> due,
    required List<Task> planned,
    required List<Task> anytime,
  }) {
    final l10n = context.l10n;
    final rows = <TasklyRowSpec>[];

    void addGroup(String id, String title, List<Task> tasks) {
      if (tasks.isEmpty) return;
      rows.add(
        TasklyRowSpec.subheader(
          key: 'myday-values-$id-header',
          title: title,
        ),
      );
      rows.addAll(
        _buildRows(
          context,
          tasks,
          showFocusBadge: true,
          subtitleByTaskId: widget.focusReasons,
        ),
      );
    }

    addGroup('due', l10n.myDayDueSoonLabel, due);
    addGroup('planned', l10n.myDayPlannedSectionTitle, planned);
    addGroup('anytime', l10n.myDayAnytimeLabel, anytime);

    return rows;
  }

  ({List<Task> due, List<Task> planned, List<Task> anytime})
  _splitValuesAligned({
    required List<Task> tasks,
    required DateTime today,
    required int dueWindowDays,
    required bool showAvailableToStart,
  }) {
    final dueLimit = today.add(
      Duration(days: dueWindowDays.clamp(1, 30) - 1),
    );

    final due = <Task>[];
    final planned = <Task>[];
    final anytime = <Task>[];

    for (final task in tasks) {
      final deadline = _deadlineDateOnly(task);
      if (deadline != null && !deadline.isAfter(dueLimit)) {
        due.add(task);
        continue;
      }

      final start = _startDateOnly(task);
      final available =
          showAvailableToStart && start != null && !start.isAfter(today);
      if (available) {
        planned.add(task);
        continue;
      }

      anytime.add(task);
    }

    return (due: due, planned: planned, anytime: anytime);
  }

  DateTime? _deadlineDateOnly(Task task) {
    final raw = task.occurrence?.deadline ?? task.deadlineDate;
    return dateOnlyOrNull(raw);
  }

  DateTime? _startDateOnly(Task task) {
    final raw = task.occurrence?.date ?? task.startDate;
    return dateOnlyOrNull(raw);
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

  List<TasklyRowSpec> _buildRows(
    BuildContext context,
    List<Task> tasks, {
    bool showFocusBadge = false,
    Map<String, String> subtitleByTaskId = const <String, String>{},
    String? completedStatusLabel,
  }) {
    final selection = context.read<SelectionCubit>();
    final selectionMode = selection.isSelectionMode;

    return tasks
        .map((task) {
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
            completedStatusLabel: completedStatusLabel,
          );

          final updatedData = TasklyTaskRowData(
            id: data.id,
            title: data.title,
            completed: data.completed,
            meta: data.meta,
            leadingChip: data.leadingChip,
            secondaryChips: data.secondaryChips,
            supportingText: subtitleByTaskId[task.id],
            supportingTooltipText: null,
            deemphasized: data.deemphasized,
            checkboxSemanticLabel: data.checkboxSemanticLabel,
            labels: labels,
          );

          return TasklyRowSpec.task(
            key: 'myday-accepted-${task.id}',
            data: updatedData,
            preset: selectionMode
                ? TasklyTaskRowPreset.bulkSelection(selected: isSelected)
                : const TasklyTaskRowPreset.standard(),
            markers: TasklyTaskRowMarkers(
              pinned: task.isPinned,
              focused: showFocusBadge,
            ),
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
        })
        .toList(growable: false);
  }

  List<TasklyRowSpec> _buildPinnedRows(
    BuildContext context,
    List<Task> tasks,
  ) {
    final selection = context.read<SelectionCubit>();
    final selectionMode = selection.isSelectionMode;

    return tasks
        .map((task) {
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
            pinLabel: context.l10n.pinAction,
            pinnedLabel: context.l10n.unpinAction,
          );

          final updatedData = TasklyTaskRowData(
            id: data.id,
            title: data.title,
            completed: data.completed,
            meta: data.meta,
            leadingChip: data.leadingChip,
            secondaryChips: data.secondaryChips,
            supportingText: data.supportingText,
            supportingTooltipText: data.supportingTooltipText,
            deemphasized: data.deemphasized,
            checkboxSemanticLabel: data.checkboxSemanticLabel,
            labels: labels,
          );

          return TasklyRowSpec.task(
            key: 'myday-pinned-${task.id}',
            data: updatedData,
            preset: selectionMode
                ? TasklyTaskRowPreset.bulkSelection(selected: isSelected)
                : const TasklyTaskRowPreset.pinnedToggle(),
            markers: TasklyTaskRowMarkers(pinned: task.isPinned),
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
              onTogglePinned: buildTaskTogglePinnedHandler(
                context,
                task: task,
                tileCapabilities: tileCapabilities,
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  Widget? _buildShowMoreFooter(
    BuildContext context, {
    required bool expanded,
    required int remaining,
    required int total,
    required VoidCallback onToggle,
    int previewCount = _previewCount,
  }) {
    if (total <= previewCount) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Center(
        child: TextButton.icon(
          onPressed: onToggle,
          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          label: Text(
            expanded
                ? context.l10n.myDayRitualShowFewer
                : context.l10n.myDayRitualShowMore(remaining, total),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
