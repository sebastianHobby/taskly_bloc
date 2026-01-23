import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_timeline_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_scope_header.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/formatters/date_label_formatter.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_entities.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

class ScheduledPage extends StatelessWidget {
  const ScheduledPage({super.key, this.scope = const GlobalScheduledScope()});

  final ScheduledScope scope;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ScheduledScreenBloc(
            taskRepository: getIt(),
            projectRepository: getIt(),
          ),
        ),
        BlocProvider(
          create: (_) => ScheduledTimelineBloc(
            occurrencesService: getIt(),
            sessionDayKeyService: getIt(),
            scope: scope,
          ),
        ),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: _ScheduledTimelineView(scope: scope),
    );
  }
}

class _ScheduledTimelineView extends StatefulWidget {
  const _ScheduledTimelineView({required this.scope});

  final ScheduledScope scope;

  @override
  State<_ScheduledTimelineView> createState() => _ScheduledTimelineViewState();
}

class _ScheduledTimelineViewState extends State<_ScheduledTimelineView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int _lastScrollSignal = 0;
  DateTime? _latestToday;
  int _latestOverdueOffset = 0;
  DateTime? _lastVisibleDay;

  @override
  void initState() {
    super.initState();

    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  void _onPositionsChanged() {
    final today = _latestToday;
    if (today == null) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final visible = positions.where((p) => p.itemTrailingEdge > 0).toList();
    if (visible.isEmpty) return;

    final minIndex = visible
        .map((p) => p.index)
        .reduce((a, b) => a < b ? a : b);
    final dayIndex = minIndex - _latestOverdueOffset;
    if (dayIndex < 0) return;

    final day = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: dayIndex));

    final last = _lastVisibleDay;
    if (last != null && _isSameDay(last, day)) return;
    _lastVisibleDay = day;

    context.read<ScheduledTimelineBloc>().add(
      ScheduledTimelineVisibleDayChanged(day: day),
    );
  }

  Future<void> _pickMonthAndJump({
    required DateTime today,
    required DateTime activeMonth,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: activeMonth,
      firstDate: today,
      lastDate: DateTime(today.year + 3, today.month, today.day),
    );

    if (picked == null) return;
    if (!mounted) return;

    context.read<ScheduledTimelineBloc>().add(
      ScheduledTimelineMonthJumpRequested(
        month: DateTime(picked.year, picked.month, 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final showScopeHeader = scope is! GlobalScheduledScope;

    return MultiBlocListener(
      listeners: [
        BlocListener<ScheduledScreenBloc, ScheduledScreenState>(
          listenWhen: (prev, next) => prev.effect != next.effect,
          listener: (context, state) async {
            final effect = state.effect;
            if (effect == null) return;

            switch (effect) {
              case ScheduledOpenTaskNew(:final defaultDeadlineDay):
                await EditorLauncher.fromGetIt().openTaskEditor(
                  context,
                  taskId: null,
                  defaultDeadlineDate: defaultDeadlineDay,
                  showDragHandle: true,
                );
              case ScheduledOpenProjectNew():
                await EditorLauncher.fromGetIt().openProjectEditor(
                  context,
                  projectId: null,
                  showDragHandle: true,
                );
              case ScheduledBulkDeadlineRescheduled(
                :final taskCount,
                :final projectCount,
                :final newDeadlineDay,
              ):
                final formatted = MaterialLocalizations.of(
                  context,
                ).formatMediumDate(newDeadlineDay);

                final parts = <String>[];
                if (taskCount > 0) {
                  parts.add(taskCount == 1 ? '1 task' : '$taskCount tasks');
                }
                if (projectCount > 0) {
                  parts.add(
                    projectCount == 1 ? '1 project' : '$projectCount projects',
                  );
                }
                final label = parts.isEmpty ? '0 items' : parts.join(' + ');
                final message = 'Rescheduled $label to $formatted';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              case ScheduledShowMessage(:final message):
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
            }

            if (context.mounted) {
              context.read<ScheduledScreenBloc>().add(
                const ScheduledEffectHandled(),
              );
            }
          },
        ),
        BlocListener<ScheduledTimelineBloc, ScheduledTimelineState>(
          listenWhen: (prev, next) {
            return prev is ScheduledTimelineLoaded &&
                next is ScheduledTimelineLoaded &&
                prev.scrollToDaySignal != next.scrollToDaySignal;
          },
          listener: (context, state) async {
            if (state is! ScheduledTimelineLoaded) return;
            if (state.scrollToDaySignal == _lastScrollSignal) return;
            _lastScrollSignal = state.scrollToDaySignal;

            final targetDay = state.scrollTargetDay;
            if (targetDay == null) return;

            final overdueOffset = state.overdue.isEmpty ? 0 : 1;
            final index =
                overdueOffset +
                targetDay
                    .difference(
                      DateTime(
                        state.today.year,
                        state.today.month,
                        state.today.day,
                      ),
                    )
                    .inDays;

            if (!_itemScrollController.isAttached) return;

            await _itemScrollController.scrollTo(
              index: index.clamp(0, 1000000),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );

            if (context.mounted) {
              context.read<ScheduledTimelineBloc>().add(
                const ScheduledTimelineScrollEffectHandled(),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<ScheduledTimelineBloc, ScheduledTimelineState>(
        builder: (context, state) {
          return switch (state) {
            ScheduledTimelineLoading() => Scaffold(
              appBar: AppBar(
                title: const Text('Scheduled'),
                actions: TasklyAppBarActions.withAttentionBell(
                  context,
                  actions: const <Widget>[],
                ),
              ),
              body: const LoadingStateWidget(
                message: 'Loading scheduled...',
              ),
            ),
            ScheduledTimelineError(:final message) => Scaffold(
              appBar: AppBar(
                title: const Text('Scheduled'),
                actions: TasklyAppBarActions.withAttentionBell(
                  context,
                  actions: const <Widget>[],
                ),
              ),
              body: ErrorStateWidget(
                message: message,
                onRetry: () => context.read<ScheduledTimelineBloc>().add(
                  const ScheduledTimelineStarted(),
                ),
              ),
            ),
            ScheduledTimelineLoaded() => _buildLoaded(
              context,
              state,
              showScopeHeader,
            ),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    ScheduledTimelineLoaded state,
    bool showScopeHeader,
  ) {
    _latestToday = state.today;
    _latestOverdueOffset = state.overdue.isEmpty ? 0 : 1;

    final today = DateTime(
      state.today.year,
      state.today.month,
      state.today.day,
    );
    final monthLabel = DateFormat.yMMMM().format(state.activeMonth);

    final overdueOffset = state.overdue.isEmpty ? 0 : 1;
    final totalDays = state.rangeEndDay.difference(today).inDays + 1;
    final itemCount = totalDays + overdueOffset;

    final occurrencesByDay = <DateTime, List<ScheduledOccurrence>>{};
    for (final o in state.occurrences) {
      if (o.tag == ScheduledDateTag.ongoing) continue;
      final d = DateTime(o.localDay.year, o.localDay.month, o.localDay.day);
      if (d.isBefore(today)) continue;
      (occurrencesByDay[d] ??= <ScheduledOccurrence>[]).add(o);
    }

    return BlocBuilder<SelectionCubit, SelectionState>(
      builder: (context, selectionState) {
        final selection = context.read<SelectionCubit>();

        final visibleEntities = <SelectionEntityMeta>[];

        for (final o in state.overdue) {
          if (o.entityType == EntityType.task && o.task != null) {
            final t = o.task!;
            visibleEntities.add(
              SelectionEntityMeta(
                key: SelectionKey(entityType: EntityType.task, entityId: t.id),
                displayName: t.name,
                canDelete: true,
                completed: t.completed,
                pinned: t.isPinned,
                canCompleteSeries: t.isRepeating && !t.seriesEnded,
              ),
            );
          } else if (o.entityType == EntityType.project && o.project != null) {
            final p = o.project!;
            visibleEntities.add(
              SelectionEntityMeta(
                key: SelectionKey(
                  entityType: EntityType.project,
                  entityId: p.id,
                ),
                displayName: p.name,
                canDelete: true,
                completed: p.completed,
                pinned: p.isPinned,
              ),
            );
          }
        }

        for (var i = 0; i < totalDays; i++) {
          final day = today.add(Duration(days: i));
          final list = occurrencesByDay[day] ?? const <ScheduledOccurrence>[];
          final sorted = list.toList(growable: false)
            ..sort(_compareOccurrences);

          for (final o in sorted) {
            if (o.entityType == EntityType.task && o.task != null) {
              final t = o.task!;
              visibleEntities.add(
                SelectionEntityMeta(
                  key: SelectionKey(
                    entityType: EntityType.task,
                    entityId: t.id,
                  ),
                  displayName: t.name,
                  canDelete: true,
                  completed: t.completed,
                  pinned: t.isPinned,
                  canCompleteSeries: t.isRepeating && !t.seriesEnded,
                ),
              );
            } else if (o.entityType == EntityType.project &&
                o.project != null) {
              final p = o.project!;
              visibleEntities.add(
                SelectionEntityMeta(
                  key: SelectionKey(
                    entityType: EntityType.project,
                    entityId: p.id,
                  ),
                  displayName: p.name,
                  canDelete: true,
                  completed: p.completed,
                  pinned: p.isPinned,
                ),
              );
            }
          }
        }

        selection.updateVisibleEntities(visibleEntities);

        final overdueTiles = state.overdue
            .map(
              (o) => _buildOccurrenceTile(
                context,
                o,
                selectionState: selectionState,
                day: DateTime(
                  o.localDay.year,
                  o.localDay.month,
                  o.localDay.day,
                ),
                today: today,
                forceDue: true,
                compact: true,
              ),
            )
            .whereType<Widget>()
            .toList(growable: false);

        return Scaffold(
          appBar: selectionState.isSelectionMode
              ? SelectionAppBar(baseTitle: 'Scheduled', onExit: () {})
              : AppBar(
                  title: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickMonthAndJump(
                      today: today,
                      activeMonth: state.activeMonth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(monthLabel),
                    ),
                  ),
                  actions: TasklyAppBarActions.withAttentionBell(
                    context,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () =>
                            context.read<ScheduledTimelineBloc>().add(
                              const ScheduledTimelineJumpToTodayRequested(),
                            ),
                        child: const Text('Today'),
                      ),
                    ],
                  ),
                ),
          floatingActionButton: selectionState.isSelectionMode
              ? null
              : EntityAddSpeedDial(
                  heroTag: 'add_speed_dial_scheduled_timeline',
                  onCreateTask: () => context.read<ScheduledScreenBloc>().add(
                    ScheduledCreateTaskForDayRequested(day: today),
                  ),
                  onCreateProject: () =>
                      context.read<ScheduledScreenBloc>().add(
                        const ScheduledCreateProjectRequested(),
                      ),
                ),
          body: Column(
            children: [
              if (showScopeHeader)
                ScheduledScopeHeader(
                  scope: widget.scope,
                ),
              Expanded(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (overdueOffset == 1 && index == 0) {
                      final actionEnabled = overdueTiles.isNotEmpty;

                      return TasklyScheduledOverdueSection(
                        model: TasklyScheduledOverdueModel(
                          title: 'Overdue',
                          countLabel: overdueTiles.length.toString(),
                          isCollapsed: state.overdueCollapsed,
                          onToggleCollapsed: () =>
                              context.read<ScheduledTimelineBloc>().add(
                                const ScheduledTimelineOverdueCollapsedToggled(),
                              ),
                          children: overdueTiles,
                          actionLabel: actionEnabled ? 'Reschedule all' : null,
                          actionTooltip: 'Reschedule overdue items',
                          onActionPressed:
                              selectionState.isSelectionMode || !actionEnabled
                              ? null
                              : () async {
                                  final newDeadlineDay =
                                      await _showRescheduleOverduePicker(
                                        context,
                                        itemCount: overdueTiles.length,
                                        today: today,
                                      );
                                  if (newDeadlineDay == null) return;
                                  if (!context.mounted) return;

                                  final taskIds = state.overdue
                                      .where(
                                        (o) => o.entityType == EntityType.task,
                                      )
                                      .map((o) => o.entityId)
                                      .toList(growable: false);
                                  final projectIds = state.overdue
                                      .where(
                                        (o) =>
                                            o.entityType == EntityType.project,
                                      )
                                      .map((o) => o.entityId)
                                      .toList(growable: false);

                                  context.read<ScheduledScreenBloc>().add(
                                    ScheduledRescheduleEntitiesDeadlineRequested(
                                      taskIds: taskIds,
                                      projectIds: projectIds,
                                      newDeadlineDay: newDeadlineDay,
                                    ),
                                  );
                                },
                        ),
                      );
                    }

                    final dayIndex = index - overdueOffset;
                    final day = today.add(Duration(days: dayIndex));

                    final list =
                        occurrencesByDay[day] ?? const <ScheduledOccurrence>[];

                    final sorted = list.toList(growable: false)
                      ..sort(_compareOccurrences);

                    final tiles = sorted
                        .map(
                          (o) => _buildOccurrenceTile(
                            context,
                            o,
                            selectionState: selectionState,
                            day: day,
                            today: today,
                            forceDue: false,
                            compact: false,
                          ),
                        )
                        .whereType<Widget>()
                        .toList(growable: false);

                    final header = DateFormat('EEEE, MMM d').format(day);
                    final count = tiles.length;
                    final countLabel = count == 0
                        ? null
                        : (count == 1 ? '1 task' : '$count tasks');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: TasklyScheduledDaySection(
                        model: TasklyScheduledDayModel(
                          day: day,
                          title: header,
                          isToday: dayIndex == 0,
                          countLabel: countLabel,
                          children: tiles,
                          emptyLabel: 'No tasks',
                          onAddRequested: selectionState.isSelectionMode
                              ? null
                              : () => context.read<ScheduledScreenBloc>().add(
                                  ScheduledCreateTaskForDayRequested(
                                    day: day,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static int _compareOccurrences(ScheduledOccurrence a, ScheduledOccurrence b) {
    final aDue = a.tag == ScheduledDateTag.due;
    final bDue = b.tag == ScheduledDateTag.due;
    if (aDue != bDue) return aDue ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static Widget? _buildOccurrenceTile(
    BuildContext context,
    ScheduledOccurrence occurrence, {
    required SelectionState selectionState,
    required DateTime day,
    required DateTime today,
    required bool forceDue,
    required bool compact,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selection = context.read<SelectionCubit>();

    // Overdue-only emphasis: only the overdue section forces the accent.
    final leadingAccentColor = forceDue ? scheme.error : null;

    if (occurrence.isTask && occurrence.task != null) {
      final task = occurrence.task!;

      final key = SelectionKey(entityType: EntityType.task, entityId: task.id);
      final isSelected = selectionState.selected.contains(key);

      final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
      final onToggle = buildTaskToggleCompletionHandler(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
      );

      final plannedDate = task.occurrence?.date ?? task.startDate;
      final plannedLabel = plannedDate == null
          ? null
          : DateLabelFormatter.format(context, plannedDate);

      final dueDate = task.occurrence?.deadline ?? task.deadlineDate;
      final dueLabel = dueDate == null
          ? null
          : DateLabelFormatter.format(
              context,
              dueDate,
            );

      final model = buildTaskListRowTileModel(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
        showProjectLabel: false,
        showDates: true,
        showOnlyDeadlineDate: false,
        showDeadlineChipOnTitleLine: false,
        showPrimaryValueOnTitleLine: false,
        showValuesInMetaLine: false,
        showSecondaryValues: false,
        overrideStartDateLabel: plannedLabel,
        overrideDeadlineDateLabel: dueLabel,
      );

      return TaskEntityTile(
        model: model,
        intent: selectionState.isSelectionMode
            ? TaskTileIntent.bulkSelection(selected: isSelected)
            : const TaskTileIntent.standardList(),
        markers: TaskTileMarkers(pinned: task.isPinned),
        actions: TaskTileActions(
          onTap: () {
            if (selection.shouldInterceptTapAsSelection()) {
              selection.handleEntityTap(key);
              return;
            }
            model.onTap();
          },
          onToggleCompletion: onToggle,
          onToggleSelected: selectionState.isSelectionMode
              ? () => selection.handleEntityTap(key)
              : null,
          onLongPress: () => selection.enterSelectionMode(
            initialSelection: key,
          ),
        ),
        leadingAccentColor: leadingAccentColor,
        compact: compact,
      );
    }

    if (occurrence.isProject && occurrence.project != null) {
      final project = occurrence.project!;

      final key = SelectionKey(
        entityType: EntityType.project,
        entityId: project.id,
      );
      final isSelected = selectionState.selected.contains(key);

      final plannedDate = project.occurrence?.date ?? project.startDate;
      final plannedLabel = plannedDate == null
          ? null
          : DateLabelFormatter.format(context, plannedDate);

      final effectiveDeadline =
          project.occurrence?.deadline ?? project.deadlineDate;
      final dueLabel = effectiveDeadline == null
          ? null
          : DateLabelFormatter.format(context, effectiveDeadline);

      final bool isOverdue =
          forceDue ||
          _isOverdueDeadline(
            effectiveDeadline,
            completed: project.completed,
            today: today,
          );

      final bool isDueToday = _isDueTodayDeadline(
        effectiveDeadline,
        completed: project.completed,
        today: today,
      );

      final bool isDueSoon = _isDueSoonDeadline(
        effectiveDeadline,
        completed: project.completed,
        today: today,
      );

      final leadingChip = project.primaryValue?.toChipData(context);

      final meta = EntityMetaLineModel(
        showDates: true,
        showOnlyDeadlineDate: false,
        showBothDatesIfPresent: true,
        startDateLabel: plannedLabel,
        deadlineDateLabel: dueLabel,
        isOverdue: isOverdue,
        isDueToday: isDueToday,
        isDueSoon: isDueSoon,
        priority: project.priority,
        showPriorityMarkerOnRight: false,
      );

      final model = ProjectTileModel(
        id: project.id,
        title: project.name,
        completed: project.completed,
        pinned: project.isPinned,
        meta: meta,
        leadingChip: leadingChip,
      );

      return ProjectEntityTile(
        model: model,
        intent: selectionState.isSelectionMode
            ? ProjectTileIntent.bulkSelection(selected: isSelected)
            : const ProjectTileIntent.standardList(),
        actions: ProjectTileActions(
          onTap: () {
            if (selection.shouldInterceptTapAsSelection()) {
              selection.handleEntityTap(key);
              return;
            }
            Routing.toProjectEdit(context, project.id);
          },
          onToggleSelected: selectionState.isSelectionMode
              ? () => selection.handleEntityTap(key)
              : null,
          onLongPress: () => selection.enterSelectionMode(
            initialSelection: key,
          ),
        ),
        leadingAccentColor: leadingAccentColor,
        compact: compact,
      );
    }

    return null;
  }

  Future<DateTime?> _showRescheduleOverduePicker(
    BuildContext context, {
    required int itemCount,
    required DateTime today,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: itemCount == 1
          ? 'Reschedule 1 item'
          : 'Reschedule $itemCount items',
    );

    if (picked == null) return null;
    return DateTime(picked.year, picked.month, picked.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isOverdueDeadline(
    DateTime? deadline, {
    required bool completed,
    required DateTime today,
  }) {
    if (deadline == null || completed) return false;
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  static bool _isDueTodayDeadline(
    DateTime? deadline, {
    required bool completed,
    required DateTime today,
  }) {
    if (deadline == null || completed) return false;
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  static bool _isDueSoonDeadline(
    DateTime? deadline, {
    required bool completed,
    required DateTime today,
  }) {
    if (deadline == null || completed) return false;
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    return daysUntil > 0 && daysUntil <= 3;
  }
}
