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
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/services.dart';
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

    final overdueCards = state.overdue
        .map((o) => _buildCardModel(context, o, forceDue: true))
        .whereType<TasklyTimelineCardModel>()
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickMonthAndJump(
            today: today,
            activeMonth: state.activeMonth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(monthLabel),
          ),
        ),
        actions: TasklyAppBarActions.withAttentionBell(
          context,
          actions: <Widget>[
            TextButton(
              onPressed: () => context.read<ScheduledTimelineBloc>().add(
                const ScheduledTimelineJumpToTodayRequested(),
              ),
              child: const Text('Today'),
            ),
          ],
        ),
      ),
      floatingActionButton: EntityAddSpeedDial(
        heroTag: 'add_speed_dial_scheduled_timeline',
        onCreateTask: () => context.read<ScheduledScreenBloc>().add(
          ScheduledCreateTaskForDayRequested(day: today),
        ),
        onCreateProject: () => context.read<ScheduledScreenBloc>().add(
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
                  final actionEnabled = overdueCards.isNotEmpty;

                  return TasklyOverdueStackSection(
                    model: TasklyOverdueStackModel(
                      title: 'Overdue',
                      countLabel: overdueCards.length.toString(),
                      isCollapsed: state.overdueCollapsed,
                      onToggleCollapsed: () =>
                          context.read<ScheduledTimelineBloc>().add(
                            const ScheduledTimelineOverdueCollapsedToggled(),
                          ),
                      cards: overdueCards,
                      actionLabel: actionEnabled ? 'Reschedule all' : null,
                      actionTooltip: 'Reschedule overdue items',
                      onActionPressed: !actionEnabled
                          ? null
                          : () async {
                              final newDeadlineDay =
                                  await _showRescheduleOverduePicker(
                                    context,
                                    itemCount: overdueCards.length,
                                    today: today,
                                  );
                              if (newDeadlineDay == null) return;
                              if (!context.mounted) return;

                              final taskIds = state.overdue
                                  .where((o) => o.entityType == EntityType.task)
                                  .map((o) => o.entityId)
                                  .toList(growable: false);
                              final projectIds = state.overdue
                                  .where(
                                    (o) => o.entityType == EntityType.project,
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
                final cards =
                    list
                        .map((o) => _buildCardModel(context, o))
                        .whereType<TasklyTimelineCardModel>()
                        .toList(growable: false)
                      ..sort(_compareCards);

                final header = DateFormat('EEEE, MMM d').format(day);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: TasklyTimelineDaySection(
                    model: TasklyTimelineDayModel(
                      day: day,
                      title: header,
                      isToday: dayIndex == 0,
                      cards: cards,
                      emptyLabel: 'No tasks',
                      onAddRequested: () => context
                          .read<ScheduledScreenBloc>()
                          .add(ScheduledCreateTaskForDayRequested(day: day)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static int _compareCards(
    TasklyTimelineCardModel a,
    TasklyTimelineCardModel b,
  ) {
    if (a.status != b.status) {
      return a.status == TasklyTimelineStatus.due ? -1 : 1;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static TasklyTimelineCardModel? _buildCardModel(
    BuildContext context,
    ScheduledOccurrence occurrence, {
    bool forceDue = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final status = (forceDue || occurrence.tag == ScheduledDateTag.due)
        ? TasklyTimelineStatus.due
        : TasklyTimelineStatus.planned;

    final accent = status == TasklyTimelineStatus.due ? scheme.error : null;

    if (occurrence.entityType == EntityType.task && occurrence.task != null) {
      final task = occurrence.task!;
      final completed = task.occurrence?.isCompleted ?? task.completed;

      final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
      final onToggle = buildTaskToggleCompletionHandler(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
      );

      return TasklyTimelineCardModel(
        key:
            '${task.id}:${occurrence.localDay.toIso8601String()}:${occurrence.tag.name}',
        title: occurrence.name,
        completed: completed,
        status: status,
        primaryValue: task.effectivePrimaryValue?.toChipData(context),
        onTap: () => Routing.toTaskEdit(context, task.id),
        onToggleCompletion: onToggle,
        leadingAccentColor: accent,
      );
    }

    if (occurrence.entityType == EntityType.project &&
        occurrence.project != null) {
      final project = occurrence.project!;

      return TasklyTimelineCardModel(
        key:
            '${project.id}:${occurrence.localDay.toIso8601String()}:${occurrence.tag.name}',
        title: occurrence.name,
        completed: project.completed,
        status: status,
        primaryValue: project.primaryValue?.toChipData(context),
        onTap: () => Routing.toProjectEdit(context, project.id),
        onToggleCompletion: null,
        leadingAccentColor: accent,
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
