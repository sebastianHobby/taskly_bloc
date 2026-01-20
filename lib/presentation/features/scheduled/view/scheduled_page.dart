import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_scope_header.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
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
          create: (_) => ScheduledFeedBloc(
            scheduledOccurrencesService: getIt(),
            homeDayService: getIt(),
            scope: scope,
          ),
        ),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: _ScheduledView(scope: scope),
    );
  }
}

class _ScheduledView extends StatefulWidget {
  const _ScheduledView({required this.scope});

  final ScheduledScope scope;

  @override
  State<_ScheduledView> createState() => _ScheduledViewState();
}

class _ScheduledViewState extends State<_ScheduledView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _todayHeaderKey = GlobalKey(debugLabel: 'scheduled_today');
  final Map<String, GlobalKey> _dayHeaderKeys = <String, GlobalKey>{};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ScheduledAgendaFilter _filter = ScheduledAgendaFilter.all;
  int _lastScrollToTodaySignal = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static String _dayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _scrollToDayIfPresent(DateTime day) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _dayHeaderKeys[_dayKey(day)];
      final ctx = key?.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    });
  }

  Future<void> _pickDayAndScroll(DateTime today) async {
    final todayDay = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: todayDay,
      firstDate: todayDay,
      lastDate: todayDay.add(const Duration(days: 30)),
    );

    if (picked == null) return;
    _scrollToDayIfPresent(DateTime(picked.year, picked.month, picked.day));
  }

  void _scrollToTodayIfPresent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _todayHeaderKey.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final showScopeHeader = scope is! GlobalScheduledScope;
    final todayUtc = getIt<HomeDayService>().todayDayKeyUtc();
    final today = DateTime(todayUtc.year, todayUtc.month, todayUtc.day);

    return MultiBlocListener(
      listeners: [
        BlocListener<ScheduledFeedBloc, ScheduledFeedState>(
          listenWhen: (previous, current) => current is ScheduledFeedLoaded,
          listener: (context, state) {
            if (state is! ScheduledFeedLoaded) return;
            if (state.scrollToTodaySignal == _lastScrollToTodaySignal) return;
            _lastScrollToTodaySignal = state.scrollToTodaySignal;
            _scrollToTodayIfPresent();
          },
        ),
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
      ],
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, selectionState) {
          return Scaffold(
            appBar: selectionState.isSelectionMode
                ? SelectionAppBar(baseTitle: 'Scheduled', onExit: () {})
                : AppBar(
                    title: const Text('Scheduled'),
                    actions: TasklyAppBarActions.withAttentionBell(
                      context,
                      actions: const <Widget>[],
                    ),
                  ),
            floatingActionButton: selectionState.isSelectionMode
                ? null
                : EntityAddSpeedDial(
                    heroTag: 'add_speed_dial_scheduled',
                    onCreateTask: () => context.read<ScheduledScreenBloc>().add(
                      ScheduledCreateTaskForDayRequested(day: today),
                    ),
                    onCreateProject: () =>
                        context.read<ScheduledScreenBloc>().add(
                          const ScheduledCreateProjectRequested(),
                        ),
                  ),
            body: BlocBuilder<ScheduledFeedBloc, ScheduledFeedState>(
              builder: (context, state) {
                final feed = switch (state) {
                  ScheduledFeedLoading() => const FeedBody.loading(),
                  ScheduledFeedError(:final message) => FeedBody.error(
                    message: message,
                    retryLabel: context.l10n.retryButton,
                    onRetry: () => context.read<ScheduledFeedBloc>().add(
                      const ScheduledFeedRetryRequested(),
                    ),
                  ),
                  ScheduledFeedLoaded(:final rows) when rows.isEmpty =>
                    FeedBody.empty(
                      child: EmptyStateWidget.noTasks(
                        title: 'Nothing scheduled',
                        description:
                            'Add planned days or due dates to see items here.',
                        actionLabel: 'Create task',
                        onAction: () => context.read<ScheduledScreenBloc>().add(
                          ScheduledCreateTaskForDayRequested(day: today),
                        ),
                      ),
                    ),
                  ScheduledFeedLoaded(:final rows) => Builder(
                    builder: (context) {
                      final selection = context.read<SelectionCubit>();

                      final metas = <SelectionEntityMeta>[];
                      for (final row in rows) {
                        if (row is! ScheduledEntityRowUiModel) continue;

                        final occurrence = row.occurrence;
                        final key = SelectionKey(
                          entityType: occurrence.ref.entityType,
                          entityId: occurrence.ref.entityId,
                        );

                        switch (occurrence.ref.entityType) {
                          case EntityType.task:
                            final task = occurrence.task;
                            if (task == null) continue;
                            metas.add(
                              SelectionEntityMeta(
                                key: key,
                                displayName: task.name,
                                canDelete: true,
                                completed: task.completed,
                                pinned: task.isPinned,
                                canCompleteSeries:
                                    task.isRepeating && !task.seriesEnded,
                              ),
                            );
                          case EntityType.project:
                            final project = occurrence.project;
                            if (project == null) continue;
                            metas.add(
                              SelectionEntityMeta(
                                key: key,
                                displayName: project.name,
                                canDelete: true,
                                completed: project.completed,
                                pinned: project.isPinned,
                                canCompleteSeries:
                                    project.isRepeating && !project.seriesEnded,
                              ),
                            );
                          case EntityType.value:
                            continue;
                        }
                      }

                      selection.updateVisibleEntities(metas);

                      return FeedBody.child(
                        child: _ScheduledAgenda(
                          rows: rows,
                          today: today,
                          scrollController: _scrollController,
                          todayHeaderKey: _todayHeaderKey,
                          dayHeaderKeys: _dayHeaderKeys,
                          searchQuery: _searchQuery,
                          filter: _filter,
                        ),
                      );
                    },
                  ),
                };

                final filterBar = Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<ScheduledAgendaFilter>(
                      segments: const <ButtonSegment<ScheduledAgendaFilter>>[
                        ButtonSegment(
                          value: ScheduledAgendaFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: ScheduledAgendaFilter.planned,
                          label: Text('Planned'),
                        ),
                        ButtonSegment(
                          value: ScheduledAgendaFilter.due,
                          label: Text('Due'),
                        ),
                      ],
                      selected: <ScheduledAgendaFilter>{_filter},
                      onSelectionChanged:
                          (Set<ScheduledAgendaFilter> selected) {
                            final next = selected.isEmpty
                                ? ScheduledAgendaFilter.all
                                : selected.first;
                            if (next == _filter) return;
                            setState(() => _filter = next);
                          },
                      showSelectedIcon: false,
                    ),
                  ),
                );

                final searchBar = Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      suffixIconConstraints: const BoxConstraints(minWidth: 0),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.trim().isNotEmpty)
                            IconButton(
                              tooltip: 'Clear search',
                              visualDensity: VisualDensity.compact,
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear_rounded),
                            ),
                          IconButton(
                            tooltip: 'Jump to today',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              context.read<ScheduledFeedBloc>().add(
                                const ScheduledJumpToTodayRequested(),
                              );
                            },
                            icon: const Icon(Icons.today_outlined),
                          ),
                          IconButton(
                            tooltip: 'Pick a date',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _pickDayAndScroll(today),
                            icon: const Icon(Icons.calendar_today_outlined),
                          ),
                        ],
                      ),
                      filled: true,
                    ),
                  ),
                );

                final content = Column(
                  children: [
                    searchBar,
                    filterBar,
                    Expanded(child: feed),
                  ],
                );

                if (!showScopeHeader) return content;

                return Column(
                  children: [
                    ScheduledScopeHeader(scope: scope),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _semanticDayTitle(BuildContext context, DateTime day, DateTime today) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  final normalizedToday = DateTime(today.year, today.month, today.day);

  final locale = Localizations.localeOf(context).toLanguageTag();
  final absolute = DateFormat('E, MMM d', locale).format(normalizedDay);

  if (_isSameDay(normalizedDay, normalizedToday)) {
    return '${context.l10n.dateToday} · $absolute';
  }

  if (_isSameDay(normalizedDay, normalizedToday.add(const Duration(days: 1)))) {
    return '${context.l10n.dateTomorrow} · $absolute';
  }

  return absolute;
}

class _ScheduledAgenda extends StatelessWidget {
  const _ScheduledAgenda({
    required this.rows,
    required this.today,
    required this.scrollController,
    required this.todayHeaderKey,
    required this.dayHeaderKeys,
    required this.searchQuery,
    required this.filter,
  });

  final List<ListRowUiModel> rows;
  final DateTime today;
  final ScrollController scrollController;
  final GlobalKey todayHeaderKey;
  final Map<String, GlobalKey> dayHeaderKeys;
  final String searchQuery;
  final ScheduledAgendaFilter filter;

  static String _dayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static ({List<String> taskIds, List<String> projectIds})
  _extractOverdueEntityIds(
    List<ListRowUiModel> rows,
    DateTime today,
  ) {
    final taskIds = <String>{};
    final projectIds = <String>{};
    var inOverdue = false;

    for (final row in rows) {
      if (row is BucketHeaderRowUiModel) {
        inOverdue = row.bucketKey == 'overdue';
        continue;
      }

      if (!inOverdue) continue;
      if (row is! ScheduledEntityRowUiModel) continue;

      final occurrence = row.occurrence;
      final todayDay = DateTime(today.year, today.month, today.day);

      switch (occurrence.ref.entityType) {
        case EntityType.task:
          final task = occurrence.task;
          if (task == null) continue;
          final deadline = task.deadlineDate;
          if (deadline == null) continue;
          final deadlineDay = DateTime(
            deadline.year,
            deadline.month,
            deadline.day,
          );
          if (deadlineDay.isBefore(todayDay)) {
            taskIds.add(task.id);
          }
        case EntityType.project:
          final project = occurrence.project;
          if (project == null) continue;
          final deadline = project.deadlineDate;
          if (deadline == null) continue;
          final deadlineDay = DateTime(
            deadline.year,

            deadline.month,
            deadline.day,
          );
          if (deadlineDay.isBefore(todayDay)) {
            projectIds.add(project.id);
          }
        case EntityType.value:
          continue;
      }
    }

    return (
      taskIds: taskIds.toList(growable: false),
      projectIds: projectIds.toList(growable: false),
    );
  }

  static Future<DateTime?> _showRescheduleOverdueSheet(
    BuildContext context, {
    required int itemCount,
    required DateTime today,
  }) async {
    final todayDay = DateTime(today.year, today.month, today.day);
    final tomorrowDay = todayDay.add(const Duration(days: 1));

    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  itemCount == 1
                      ? 'Reschedule 1 overdue item'
                      : 'Reschedule $itemCount overdue items',
                ),
                subtitle: const Text('Pick a new due date.'),
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Today'),
                onTap: () => Navigator.of(sheetContext).pop(todayDay),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tomorrow'),
                onTap: () => Navigator.of(sheetContext).pop(tomorrowDay),
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Pick a date…'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: tomorrowDay,
                    firstDate: todayDay,
                    lastDate: todayDay.add(const Duration(days: 365)),
                  );
                  if (picked == null) return;
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop(
                    DateTime(picked.year, picked.month, picked.day),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();

    final overdueIds = _extractOverdueEntityIds(rows, today);
    final overdueTaskIds = overdueIds.taskIds;
    final overdueProjectIds = overdueIds.projectIds;
    final overdueCount = overdueTaskIds.length + overdueProjectIds.length;

    var hasOverdueBucket = false;
    var overdueCollapsed = false;
    var inOverdue = false;
    final overdueItems = <ScheduledOccurrence>[];

    final dayPlannedRows = <DateTime, List<TasklyAgendaRowModel>>{};
    final dayDueRows = <DateTime, List<TasklyAgendaRowModel>>{};
    final dayDueEntityKeys = <DateTime, Set<String>>{};

    DateTime? currentDay;

    void addPlanned(DateTime day, TasklyAgendaRowModel row, String entityKey) {
      final dueKeys = dayDueEntityKeys[day] ??= <String>{};
      if (dueKeys.contains(entityKey)) return;
      (dayPlannedRows[day] ??= <TasklyAgendaRowModel>[]).add(row);
    }

    void addDue(DateTime day, TasklyAgendaRowModel row, String entityKey) {
      final dueKeys = dayDueEntityKeys[day] ??= <String>{};
      dueKeys.add(entityKey);
      (dayDueRows[day] ??= <TasklyAgendaRowModel>[]).add(row);

      final planned = dayPlannedRows[day];
      if (planned == null || planned.isEmpty) return;
      dayPlannedRows[day] = planned
          .where(
            (r) => switch (r) {
              TasklyAgendaTaskRowModel() => 'task:${r.entityId}' != entityKey,
              TasklyAgendaProjectRowModel() =>
                'project:${r.entityId}' != entityKey,
              _ => true,
            },
          )
          .toList(growable: false);
    }

    for (final row in rows) {
      switch (row) {
        case BucketHeaderRowUiModel(:final bucketKey, :final isCollapsed):
          inOverdue = bucketKey == 'overdue';
          if (inOverdue) {
            hasOverdueBucket = true;
            overdueCollapsed = isCollapsed;
          }
          currentDay = null;

        case DateHeaderRowUiModel(:final date):
          inOverdue = false;
          currentDay = DateTime(date.year, date.month, date.day);
          dayPlannedRows.putIfAbsent(
            currentDay,
            () => <TasklyAgendaRowModel>[],
          );
          dayDueRows.putIfAbsent(currentDay, () => <TasklyAgendaRowModel>[]);

        case ScheduledEntityRowUiModel(:final occurrence):
          if (query.isNotEmpty &&
              !occurrence.name.toLowerCase().contains(query)) {
            continue;
          }

          if (inOverdue) {
            if (!overdueCollapsed) overdueItems.add(occurrence);
            continue;
          }

          final day = currentDay;
          if (day == null) continue;

          if (occurrence.tag == ScheduledDateTag.ongoing) continue;

          // Build a minimal tile row model.
          final rowModel = _buildAgendaRowForOccurrence(
            context,
            occurrence: occurrence,
          );
          if (rowModel == null) continue;

          final entityKey =
              '${occurrence.entityType.name}:${occurrence.entityId}';

          switch (occurrence.tag) {
            case ScheduledDateTag.due:
              addDue(day, rowModel, entityKey);
            case ScheduledDateTag.starts:
              addPlanned(day, rowModel, entityKey);
            case ScheduledDateTag.ongoing:
              continue;
          }

        default:
          continue;
      }
    }

    final cards = <TasklyAgendaCardModel>[];

    if (hasOverdueBucket) {
      final overdueDueRows = overdueItems
          .map(
            (o) => _buildAgendaRowForOccurrence(context, occurrence: o),
          )
          .whereType<TasklyAgendaRowModel>()
          .toList(growable: false);

      if (filter != ScheduledAgendaFilter.planned) {
        final action = overdueCount > 0
            ? TasklyAgendaCardHeaderAction(
                label: 'Reschedule all',
                icon: Icons.event,
                tooltip: 'Reschedule overdue items',
                onPressed: () async {
                  final newDeadlineDay = await _showRescheduleOverdueSheet(
                    context,
                    itemCount: overdueCount,
                    today: today,
                  );
                  if (newDeadlineDay == null) return;
                  if (!context.mounted) return;
                  context.read<ScheduledScreenBloc>().add(
                    ScheduledRescheduleEntitiesDeadlineRequested(
                      taskIds: overdueTaskIds,
                      projectIds: overdueProjectIds,
                      newDeadlineDay: newDeadlineDay,
                    ),
                  );
                },
              )
            : null;

        cards.add(
          TasklyAgendaCardModel(
            key: 'overdue',
            title: 'Overdue',
            isCollapsed: overdueCollapsed,
            onHeaderTap: () => context.read<ScheduledFeedBloc>().add(
              const ScheduledBucketCollapseToggled(bucketKey: 'overdue'),
            ),
            action: action,
            dueRows: overdueDueRows,
          ),
        );
      }
    }

    for (final entry in dayDueRows.entries) {
      final day = entry.key;
      final planned = dayPlannedRows[day] ?? const <TasklyAgendaRowModel>[];
      final due = entry.value;

      final effectivePlanned = (filter == ScheduledAgendaFilter.due)
          ? const <TasklyAgendaRowModel>[]
          : planned;
      final effectiveDue = (filter == ScheduledAgendaFilter.planned)
          ? const <TasklyAgendaRowModel>[]
          : due;

      if (effectivePlanned.isEmpty && effectiveDue.isEmpty) continue;

      final dayKey = _dayKey(day);
      final headerKey = _isSameDay(day, today)
          ? todayHeaderKey
          : dayHeaderKeys.putIfAbsent(dayKey, GlobalKey.new);

      cards.add(
        TasklyAgendaCardModel(
          key: dayKey,
          title: _semanticDayTitle(context, day, today),
          headerKey: headerKey,
          plannedRows: effectivePlanned,
          dueRows: effectiveDue,
        ),
      );
    }

    return TasklyAgendaSection(
      cards: cards,
      controller: scrollController,
    );
  }

  static TasklyAgendaRowModel? _buildAgendaRowForOccurrence(
    BuildContext context, {
    required ScheduledOccurrence occurrence,
  }) {
    final normalizedDay = DateTime(
      occurrence.localDay.year,
      occurrence.localDay.month,
      occurrence.localDay.day,
    );

    final rowKey =
        '${occurrence.entityType.name}:${occurrence.entityId}:${_dayKey(normalizedDay)}:${occurrence.tag.name}';

    if (occurrence.entityType == EntityType.task && occurrence.task != null) {
      final task = occurrence.task!;
      final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);

      final selection = context.read<SelectionCubit>();
      final key = SelectionKey(entityType: EntityType.task, entityId: task.id);
      final selectionMode = selection.isSelectionMode;
      final isSelected = selection.isSelected(key);

      final model = buildTaskListRowTileModel(
        context,
        task: task,
        tileCapabilities: tileCapabilities,
        showProjectLabel: false,
        showDates: false,
        showOnlyDeadlineDate: false,
        showPrimaryValueOnTitleLine: true,
        showValuesInMetaLine: false,
        showSecondaryValues: false,
        showPriorityMarkerOnRight: false,
        showRepeatIcon: false,
        showOverflowEllipsisWhenMetaHidden: false,
      );

      return TasklyAgendaTaskRowModel(
        key: rowKey,
        depth: 0,
        entityId: task.id,
        model: model,
        intent: selectionMode
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
          onLongPress: () {
            selection.enterSelectionMode(initialSelection: key);
          },
          onToggleSelected: () =>
              selection.toggleSelection(key, extendRange: false),
          onToggleCompletion: buildTaskToggleCompletionHandler(
            context,
            task: task,
            tileCapabilities: tileCapabilities,
          ),
          onOverflowMenuRequestedAt: null,
        ),
      );
    }

    if (occurrence.entityType == EntityType.project &&
        occurrence.project != null) {
      final project = occurrence.project!;
      final selection = context.read<SelectionCubit>();
      final key = SelectionKey(
        entityType: EntityType.project,
        entityId: project.id,
      );
      final selectionMode = selection.isSelectionMode;
      final isSelected = selection.isSelected(key);

      return TasklyAgendaProjectRowModel(
        key: rowKey,
        depth: 0,
        entityId: project.id,
        model: buildProjectListRowTileModel(
          context,
          project: project,
          taskCount: project.taskCount,
          completedTaskCount: project.completedTaskCount,
          showDates: false,
          showOnlyDeadlineDate: false,
          showPrimaryValueOnTitleLine: true,
          showValuesInMetaLine: false,
          showSecondaryValues: false,
          showPriorityMarkerOnRight: false,
          showRepeatIcon: false,
          showOverflowEllipsisWhenMetaHidden: false,
        ),
        intent: selectionMode
            ? ProjectTileIntent.bulkSelection(selected: isSelected)
            : const ProjectTileIntent.agenda(),
        actions: ProjectTileActions(
          onTap: () {
            if (selection.shouldInterceptTapAsSelection()) {
              selection.handleEntityTap(key);
              return;
            }
            Routing.toProjectEdit(context, project.id);
          },
          onLongPress: () {
            selection.enterSelectionMode(initialSelection: key);
          },
          onToggleSelected: () =>
              selection.toggleSelection(key, extendRange: false),
          onOverflowMenuRequestedAt: null,
        ),
      );
    }

    return null;
  }
}

enum ScheduledAgendaFilter { all, planned, due }
