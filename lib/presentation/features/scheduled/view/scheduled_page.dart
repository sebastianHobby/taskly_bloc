import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_timeline_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_scope_header.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

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
                centerTitle: true,
                title: const Text('Schedule'),
                toolbarHeight: TasklyChromeTheme.of(context).scheduledAppBarHeight,
                leading: _CircleIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                actions: TasklyAppBarActions.withAttentionBell(
                  context,
                  actions: [
                    _CircleIconButton(
                      icon: Icons.search,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              body: const TasklyFeedRenderer(
                spec: TasklyFeedSpec.loading(),
              ),
            ),
            ScheduledTimelineError(:final message) => Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Schedule'),
                toolbarHeight: TasklyChromeTheme.of(context).scheduledAppBarHeight,
                leading: _CircleIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                actions: TasklyAppBarActions.withAttentionBell(
                  context,
                  actions: [
                    _CircleIconButton(
                      icon: Icons.search,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              body: TasklyFeedRenderer(
                spec: TasklyFeedSpec.error(
                  message: message,
                  retryLabel: 'Retry',
                  onRetry: () => context.read<ScheduledTimelineBloc>().add(
                    const ScheduledTimelineStarted(),
                  ),
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

        final overdueRows = state.overdue
            .map(
              (o) => _buildOccurrenceRow(
                context,
                o,
                selectionState: selectionState,
              ),
            )
            .whereType<TasklyRowSpec>()
            .toList(growable: false);

        return Scaffold(
          appBar: selectionState.isSelectionMode
              ? SelectionAppBar(baseTitle: 'Schedule', onExit: () {})
              : AppBar(
                  centerTitle: true,
                  title: _ScheduledMonthHeader(
                    activeMonth: state.activeMonth,
                    today: today,
                    onMonthSelected: (month) =>
                        context.read<ScheduledTimelineBloc>().add(
                              ScheduledTimelineMonthJumpRequested(month: month),
                            ),
                    onPickMonthRequested: () => _pickMonthAndJump(
                      today: today,
                      activeMonth: state.activeMonth,
                    ),
                  ),
                  toolbarHeight:
                      TasklyChromeTheme.of(context).scheduledAppBarHeight,
                  leading: _CircleIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  actions: TasklyAppBarActions.withAttentionBell(
                    context,
                    actions: [
                      TextButton.icon(
                        onPressed: () => context
                            .read<ScheduledTimelineBloc>()
                            .add(const ScheduledTimelineJumpToTodayRequested()),
                        icon: const Icon(Icons.today_rounded),
                        label: const Text('Today'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          textStyle: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      _CircleIconButton(
                        icon: Icons.search,
                        onPressed: () {},
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
                      final actionEnabled = overdueRows.isNotEmpty;

                      return TasklyFeedRenderer.buildSection(
                        TasklySectionSpec.scheduledOverdue(
                          id: 'scheduled-overdue',
                          title: 'Overdue',
                          countLabel: overdueRows.length.toString(),
                          isCollapsed: state.overdueCollapsed,
                          onToggleCollapsed: () =>
                              context.read<ScheduledTimelineBloc>().add(
                                const ScheduledTimelineOverdueCollapsedToggled(),
                              ),
                          rows: overdueRows,
                          actionLabel: actionEnabled ? 'Reschedule all' : null,
                          actionTooltip: 'Reschedule overdue items',
                          onActionPressed:
                              selectionState.isSelectionMode || !actionEnabled
                              ? null
                              : () async {
                                  final newDeadlineDay =
                                      await _showRescheduleOverduePicker(
                                        context,
                                        itemCount: overdueRows.length,
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

                    final rows = sorted
                        .map(
                          (o) => _buildOccurrenceRow(
                            context,
                            o,
                            selectionState: selectionState,
                          ),
                        )
                        .whereType<TasklyRowSpec>()
                        .toList(growable: false);

                    final header = DateFormat('EEEE, MMM d').format(day);
                    final count = rows.length;
                    final countLabel = count == 0
                        ? null
                        : (count == 1 ? '1 task' : '$count tasks');

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: TasklyChromeTheme.of(context)
                            .scheduledDaySectionSpacing,
                      ),
                      child: TasklyFeedRenderer.buildSection(
                        TasklySectionSpec.scheduledDay(
                          id: 'scheduled-${day.toIso8601String()}',
                          day: day,
                          title: header,
                          isToday: dayIndex == 0,
                          countLabel: countLabel,
                          rows: rows,
                          emptyLabel: 'No tasks',
                          onAddRequested: null,
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

  static TasklyRowSpec? _buildOccurrenceRow(
    BuildContext context,
    ScheduledOccurrence occurrence, {
    required SelectionState selectionState,
  }) {
    final selection = context.read<SelectionCubit>();

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

      final data = buildTaskRowData(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
      );

      final openEditor = buildTaskOpenEditorHandler(context, task: task);

      return TasklyRowSpec.task(
        key: 'scheduled-task-${task.id}-${occurrence.localDay.toIso8601String()}',
        data: data,
        markers: TasklyTaskRowMarkers(pinned: task.isPinned),
        preset: selectionState.isSelectionMode
            ? TasklyTaskRowPreset.bulkSelection(selected: isSelected)
            : const TasklyTaskRowPreset.standard(),
        emphasis:
            data.meta.isOverdue
                ? TasklyRowEmphasis.overdue
                : TasklyRowEmphasis.none,
        actions: TasklyTaskRowActions(
          onTap: () {
            if (selection.shouldInterceptTapAsSelection()) {
              selection.handleEntityTap(key);
              return;
            }
            openEditor();
          },
          onToggleCompletion: onToggle,
          onToggleSelected: selectionState.isSelectionMode
              ? () => selection.handleEntityTap(key)
              : null,
          onLongPress: () => selection.enterSelectionMode(
            initialSelection: key,
          ),
        ),
      );
    }

    if (occurrence.isProject && occurrence.project != null) {
      final project = occurrence.project!;

      final key = SelectionKey(
        entityType: EntityType.project,
        entityId: project.id,
      );
      final isSelected = selectionState.selected.contains(key);

      final data = buildProjectRowData(
        context,
        project: project,
      );

      return TasklyRowSpec.project(
        key:
            'scheduled-project-${project.id}-${occurrence.localDay.toIso8601String()}',
        data: data,
        preset: selectionState.isSelectionMode
            ? TasklyProjectRowPreset.bulkSelection(selected: isSelected)
            : const TasklyProjectRowPreset.standard(),
        emphasis:
            data.meta.isOverdue
                ? TasklyRowEmphasis.overdue
                : TasklyRowEmphasis.none,
        actions: TasklyProjectRowActions(
            onTap: () {
              if (selection.shouldInterceptTapAsSelection()) {
                selection.handleEntityTap(key);
                return;
              }
              Routing.pushProjectAnytime(context, project.id);
            },
          onToggleSelected: selectionState.isSelectionMode
              ? () => selection.handleEntityTap(key)
              : null,
          onLongPress: () => selection.enterSelectionMode(
            initialSelection: key,
          ),
        ),
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

}

class _ScheduledMonthHeader extends StatelessWidget {
  const _ScheduledMonthHeader({
    required this.activeMonth,
    required this.today,
    required this.onMonthSelected,
    required this.onPickMonthRequested,
  });

  final DateTime activeMonth;
  final DateTime today;
  final ValueChanged<DateTime> onMonthSelected;
  final VoidCallback onPickMonthRequested;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final active = DateTime(activeMonth.year, activeMonth.month, 1);
    final start = DateTime(today.year, today.month, 1);
    final months = _buildMonthOptions(start);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Schedule',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<DateTime?>(
            value: active,
            icon: const Icon(Icons.expand_more_rounded),
            borderRadius: BorderRadius.circular(12),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            items: [
              for (final month in months)
                DropdownMenuItem<DateTime?>(
                  value: month,
                  child: Text(
                    DateFormat.yMMM(locale.toLanguageTag()).format(month),
                  ),
                ),
              const DropdownMenuItem<DateTime?>(
                value: null,
                child: Text('Pick a month...'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                onPickMonthRequested();
                return;
              }
              onMonthSelected(value);
            },
          ),
        ),
      ],
    );
  }
}

List<DateTime> _buildMonthOptions(DateTime startMonth) {
  final start = DateTime(startMonth.year, startMonth.month, 1);
  return List<DateTime>.generate(
    37,
    (index) => DateTime(start.year, start.month + index, 1),
  );
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chrome = TasklyChromeTheme.of(context);
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest.withValues(
          alpha: chrome.iconButtonBackgroundAlpha,
        ),
        foregroundColor: scheme.onSurface,
        shape: const CircleBorder(),
        minimumSize: Size.square(chrome.iconButtonMinSize),
        padding: chrome.iconButtonPadding,
      ),
    );
  }
}
