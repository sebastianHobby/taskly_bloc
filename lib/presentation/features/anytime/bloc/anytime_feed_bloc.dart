import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:rxdart/rxdart.dart';

import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';

sealed class AnytimeFeedEvent {
  const AnytimeFeedEvent();
}

final class AnytimeFeedStarted extends AnytimeFeedEvent {
  const AnytimeFeedStarted();
}

final class AnytimeFeedRetryRequested extends AnytimeFeedEvent {
  const AnytimeFeedRetryRequested();
}

final class AnytimeFeedFocusOnlyChanged extends AnytimeFeedEvent {
  const AnytimeFeedFocusOnlyChanged({required this.enabled});

  final bool enabled;
}

final class AnytimeFeedShowStartLaterItemsChanged extends AnytimeFeedEvent {
  const AnytimeFeedShowStartLaterItemsChanged({required this.enabled});

  /// When true, items with a future planned day (start date) are included.
  final bool enabled;
}

final class AnytimeFeedSearchQueryChanged extends AnytimeFeedEvent {
  const AnytimeFeedSearchQueryChanged({required this.query});

  final String query;
}

final class AnytimeFeedInboxCollapsedChanged extends AnytimeFeedEvent {
  const AnytimeFeedInboxCollapsedChanged({required this.collapsed});

  final bool collapsed;
}

sealed class AnytimeFeedState {
  const AnytimeFeedState();
}

final class AnytimeFeedLoading extends AnytimeFeedState {
  const AnytimeFeedLoading();
}

final class AnytimeFeedLoaded extends AnytimeFeedState {
  const AnytimeFeedLoaded({required this.rows});

  final List<ListRowUiModel> rows;
}

final class AnytimeFeedError extends AnytimeFeedState {
  const AnytimeFeedError({required this.message});

  final String message;
}

class AnytimeFeedBloc extends Bloc<AnytimeFeedEvent, AnytimeFeedState> {
  AnytimeFeedBloc({
    required TaskRepositoryContract taskRepository,
    required MyDayRepositoryContract myDayRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    AnytimeScope? scope,
  }) : _taskRepository = taskRepository,
       _myDayRepository = myDayRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _scope = scope,
       super(const AnytimeFeedLoading()) {
    on<AnytimeFeedStarted>(_onStarted, transformer: restartable());
    on<AnytimeFeedRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );
    on<AnytimeFeedFocusOnlyChanged>(_onFocusOnlyChanged);
    on<AnytimeFeedShowStartLaterItemsChanged>(_onShowStartLaterItemsChanged);
    on<AnytimeFeedSearchQueryChanged>(_onSearchQueryChanged);
    on<AnytimeFeedInboxCollapsedChanged>(_onInboxCollapsedChanged);

    add(const AnytimeFeedStarted());
  }

  final TaskRepositoryContract _taskRepository;
  final MyDayRepositoryContract _myDayRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final AnytimeScope? _scope;

  List<Task> _latestTasks = const <Task>[];
  Map<String, OccurrenceData> _nextTaskOccurrenceById =
      const <String, OccurrenceData>{};
  Set<String> _todaySelectedTaskIds = const <String>{};
  DateTime _todayDayKeyUtc = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
  bool _focusOnly = false;
  bool _showStartLaterItems = false;
  bool _inboxCollapsed = false;
  String _searchQuery = '';

  Future<void> _onStarted(
    AnytimeFeedStarted event,
    Emitter<AnytimeFeedState> emit,
  ) async {
    await _bind(emit);
  }

  Future<void> _onRetryRequested(
    AnytimeFeedRetryRequested event,
    Emitter<AnytimeFeedState> emit,
  ) async {
    emit(const AnytimeFeedLoading());
    await _bind(emit);
  }

  void _onFocusOnlyChanged(
    AnytimeFeedFocusOnlyChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _focusOnly = event.enabled;
    _emitRows(emit);
  }

  void _onShowStartLaterItemsChanged(
    AnytimeFeedShowStartLaterItemsChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _showStartLaterItems = event.enabled;
    _emitRows(emit);
  }

  void _onSearchQueryChanged(
    AnytimeFeedSearchQueryChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _searchQuery = event.query.trim();
    _emitRows(emit);
  }

  void _onInboxCollapsedChanged(
    AnytimeFeedInboxCollapsedChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _inboxCollapsed = event.collapsed;
    _emitRows(emit);
  }

  Future<void> _bind(Emitter<AnytimeFeedState> emit) async {
    final query = _scopeQuery(TaskQuery.incomplete(), _scope);

    final dayKeyStream = Rx.merge<DateTime>([
      Stream<DateTime>.value(_dayKeyService.todayDayKeyUtc()),
      _temporalTriggerService.events
          .where(
            (event) => event is HomeDayBoundaryCrossed || event is AppResumed,
          )
          .map((_) => _dayKeyService.todayDayKeyUtc()),
    ]).distinct().shareValue();

    final todaySelectionIdsStream = dayKeyStream
        .switchMap(_myDayRepository.watchDay)
        .map((picks) {
          if (picks.ritualCompletedAtUtc == null) return <String>{};
          return picks.selectedTaskIds
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet();
        })
        .distinct(_areSetsEqual);

    final nextOccurrenceByTaskIdStream = dayKeyStream.switchMap((dayKey) {
      // Anytime is not date-scoped, but "Complete" should target the next
      // occurrence for repeating tasks. We maintain a map of the next
      // uncompleted occurrence per task id.
      //
      // Keep the range wide enough to catch rolling schedules.
      final rangeStart = dayKey.subtract(const Duration(days: 365));
      final rangeEnd = dayKey.add(const Duration(days: 730));

      return _taskRepository
          .watchOccurrences(rangeStart: rangeStart, rangeEnd: rangeEnd)
          .map(
            (occurrences) =>
                NextOccurrenceSelector.nextUncompletedTaskOccurrenceByTaskId(
                  expandedTasks: occurrences,
                  asOfDay: dayKey,
                ),
          );
    });

    await Future.wait<void>([
      emit.onEach<DateTime>(
        dayKeyStream,
        onData: (dayKey) {
          _todayDayKeyUtc = dayKey;
          _emitRows(emit);
        },
        onError: (error, stackTrace) {
          emit(AnytimeFeedError(message: error.toString()));
        },
      ),
      emit.onEach<List<Task>>(
        _taskRepository.watchAll(query),
        onData: (tasks) {
          _latestTasks = tasks;
          _emitRows(emit);
        },
        onError: (error, stackTrace) {
          emit(AnytimeFeedError(message: error.toString()));
        },
      ),
      emit.onEach<Set<String>>(
        todaySelectionIdsStream,
        onData: (selectedIds) {
          _todaySelectedTaskIds = selectedIds;
          _emitRows(emit);
        },
        onError: (error, stackTrace) {
          emit(AnytimeFeedError(message: error.toString()));
        },
      ),
      emit.onEach<Map<String, OccurrenceData>>(
        nextOccurrenceByTaskIdStream,
        onData: (map) {
          _nextTaskOccurrenceById = map;
          _emitRows(emit);
        },
        onError: (error, stackTrace) {
          emit(AnytimeFeedError(message: error.toString()));
        },
      ),
    ]);
  }

  TaskQuery _scopeQuery(TaskQuery base, AnytimeScope? scope) {
    if (scope == null) return base;

    return switch (scope) {
      AnytimeProjectScope(:final projectId) => base.withAdditionalPredicates([
        TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: projectId,
        ),
      ]),
      AnytimeValueScope(:final valueId) => base.withAdditionalPredicates([
        TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: [valueId],
          includeInherited: true,
        ),
      ]),
    };
  }

  void _emitRows(Emitter<AnytimeFeedState> emit) {
    try {
      final search = _searchQuery.toLowerCase();

      final tasks = _latestTasks
          .where((t) => !_focusOnly || _todaySelectedTaskIds.contains(t.id))
          .where((t) => _showStartLaterItems || !_isStartLater(t))
          .where((t) => search.isEmpty || _matchesSearch(t, search))
          .toList(growable: false);

      final tasksWithNextOccurrence = tasks
          .map(_decorateWithNextOccurrence)
          .toList(growable: false);

      final rows = _mapToRows(tasksWithNextOccurrence);
      emit(AnytimeFeedLoaded(rows: rows));
    } catch (e) {
      emit(AnytimeFeedError(message: e.toString()));
    }
  }

  bool _areSetsEqual(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  Task _decorateWithNextOccurrence(Task task) {
    if (!task.isRepeating || task.seriesEnded) return task;

    final next = _nextTaskOccurrenceById[task.id];
    if (next == null) return task;

    return task.copyWith(occurrence: next);
  }

  bool _isStartLater(Task task) {
    final taskStart = task.startDate;
    if (taskStart != null && taskStart.isAfter(_todayDayKeyUtc)) return true;

    final projectStart = task.project?.startDate;
    if (projectStart != null && projectStart.isAfter(_todayDayKeyUtc)) {
      return true;
    }

    return false;
  }

  bool _matchesSearch(Task task, String searchLower) {
    final title = task.name.trim().toLowerCase();
    if (title.contains(searchLower)) return true;

    final projectName = task.project?.name.trim().toLowerCase();
    if (projectName != null && projectName.contains(searchLower)) return true;

    final valueName = task.effectivePrimaryValue?.name.trim().toLowerCase();
    if (valueName != null && valueName.contains(searchLower)) return true;

    return false;
  }

  List<ListRowUiModel> _mapToRows(List<Task> tasks) {
    if (tasks.isEmpty) return const <ListRowUiModel>[];

    final scopedValueId = switch (_scope) {
      AnytimeValueScope(:final valueId) => valueId,
      _ => null,
    };
    final scopedProjectId = switch (_scope) {
      AnytimeProjectScope(:final projectId) => projectId,
      _ => null,
    };

    final rows = <ListRowUiModel>[];

    final canShowGlobalInbox = scopedProjectId == null;

    final inboxTasks = !canShowGlobalInbox
        ? const <Task>[]
        : tasks
              .where((t) {
                final pid = t.projectId;
                return pid == null || pid.trim().isEmpty;
              })
              .toList(growable: false);

    if (inboxTasks.isNotEmpty) {
      rows.add(
        ProjectHeaderRowUiModel(
          rowKey: RowKey.v1(
            screen: 'anytime',
            rowType: 'group_header',
            params: <String, String>{
              'kind': 'project',
              'project': 'inbox',
              'scope': scopedValueId ?? 'all',
            },
          ),
          depth: 0,
          title: 'Inbox',
          projectRef: const ProjectGroupingRef.inbox(),
          trailingLabel: '${inboxTasks.length}',
          isCollapsed: _inboxCollapsed,
        ),
      );

      if (!_inboxCollapsed) {
        final sortedInboxTasks = inboxTasks.toList(growable: false)
          ..sort(_compareTasks);

        for (final task in sortedInboxTasks) {
          rows.add(
            TaskRowUiModel(
              rowKey: RowKey.v1(
                screen: 'anytime',
                rowType: 'task',
                params: <String, String>{'id': task.id},
              ),
              depth: 1,
              task: task,
              showProjectLabel: false,
            ),
          );
        }
      }
    }

    final nonInboxTasks = canShowGlobalInbox
        ? tasks
              .where((t) {
                final pid = t.projectId;
                return pid != null && pid.trim().isNotEmpty;
              })
              .toList(growable: false)
        : tasks;

    if (nonInboxTasks.isEmpty) return rows;

    final groups = <String, _ValueGroup>{};

    for (final task in nonInboxTasks) {
      final valueId = task.effectivePrimaryValueId;
      final key = valueId ?? '__none__';

      final group = groups.putIfAbsent(
        key,
        () => _ValueGroup(
          valueId: valueId,
          value: task.effectivePrimaryValue,
        ),
      );

      group.addTask(task);
    }

    final sortedGroups = groups.values.toList(growable: false)
      ..sort(_compareValueGroups);

    for (final group in sortedGroups) {
      final valueTitle = group.value?.name ?? 'No Value Assigned';

      final includeValueHeader =
          !(scopedValueId != null && group.valueId == scopedValueId);

      final projectHeaderDepth = includeValueHeader ? 1 : 0;

      if (includeValueHeader) {
        rows.add(
          ValueHeaderRowUiModel(
            rowKey: RowKey.v1(
              screen: 'anytime',
              rowType: 'group_header',
              params: <String, String>{
                'kind': 'value',
                'valueId': group.valueId ?? 'none',
              },
            ),
            depth: 0,
            title: valueTitle,
            valueId: group.valueId,
            priority: group.value?.priority,
            isTappableToScope: false,
          ),
        );
      }

      final projectGroups = group.projectGroups.toList(growable: false)
        ..sort(_compareProjectGroups);

      for (final pg in projectGroups) {
        final includeProjectHeader = !(switch (pg.projectRef) {
          ProjectProjectGroupingRef(:final projectId) =>
            scopedProjectId != null && projectId == scopedProjectId,
          InboxProjectGroupingRef() => false,
        });

        final taskDepth = includeProjectHeader
            ? projectHeaderDepth + 1
            : projectHeaderDepth;

        if (includeProjectHeader) {
          rows.add(
            ProjectHeaderRowUiModel(
              rowKey: RowKey.v1(
                screen: 'anytime',
                rowType: 'group_header',
                params: <String, String>{
                  'kind': 'project',
                  'valueId': group.valueId ?? 'none',
                  'project': pg.projectRef.stableKey,
                },
              ),
              depth: projectHeaderDepth,
              title: pg.title,
              projectRef: pg.projectRef,
            ),
          );
        }

        final sortedTasks = pg.tasks.toList(growable: false)
          ..sort(_compareTasks);

        for (final task in sortedTasks) {
          rows.add(
            TaskRowUiModel(
              rowKey: RowKey.v1(
                screen: 'anytime',
                rowType: 'task',
                params: <String, String>{'id': task.id},
              ),
              depth: taskDepth,
              task: task,
              showProjectLabel: false,
            ),
          );
        }
      }
    }

    return rows;
  }

  int _compareValueGroups(_ValueGroup a, _ValueGroup b) {
    final aNone = a.valueId == null;
    final bNone = b.valueId == null;
    if (aNone != bNone) return aNone ? 1 : -1;

    final ap = a.value?.priority ?? ValuePriority.medium;
    final bp = b.value?.priority ?? ValuePriority.medium;
    final byP = _priorityRank(ap).compareTo(_priorityRank(bp));
    if (byP != 0) return byP;

    final an = (a.value?.name ?? '').toLowerCase();
    final bn = (b.value?.name ?? '').toLowerCase();
    final byN = an.compareTo(bn);
    if (byN != 0) return byN;

    return (a.valueId ?? '').compareTo(b.valueId ?? '');
  }

  int _priorityRank(ValuePriority p) {
    return switch (p) {
      ValuePriority.high => 0,
      ValuePriority.medium => 1,
      ValuePriority.low => 2,
    };
  }

  int _compareProjectGroups(_ProjectGroup a, _ProjectGroup b) {
    if (a.projectRef.isInbox != b.projectRef.isInbox) {
      return a.projectRef.isInbox ? -1 : 1;
    }

    final byName = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (byName != 0) return byName;

    return (a.projectRef.projectId ?? '').compareTo(
      b.projectRef.projectId ?? '',
    );
  }

  int _compareTasks(Task a, Task b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;

    final ad = a.occurrence?.deadline ?? a.deadlineDate;
    final bd = b.occurrence?.deadline ?? b.deadlineDate;
    if (ad == null && bd != null) return 1;
    if (ad != null && bd == null) return -1;
    if (ad != null && bd != null) {
      final byDeadline = ad.compareTo(bd);
      if (byDeadline != 0) return byDeadline;
    }

    final ap = a.priority;
    final bp = b.priority;
    if (ap == null && bp != null) return 1;
    if (ap != null && bp == null) return -1;
    if (ap != null && bp != null) {
      final byPriority = ap.compareTo(bp);
      if (byPriority != 0) return byPriority;
    }

    final an = a.name.trim().toLowerCase();
    final bn = b.name.trim().toLowerCase();
    final byName = an.compareTo(bn);
    if (byName != 0) return byName;

    return a.id.compareTo(b.id);
  }
}

class _ValueGroup {
  _ValueGroup({required this.valueId, required this.value});

  final String? valueId;
  final Value? value;

  final Map<String, _ProjectGroup> _projectGroupsByKey =
      <String, _ProjectGroup>{};

  Iterable<_ProjectGroup> get projectGroups => _projectGroupsByKey.values;

  void addTask(Task task) {
    final projectRef = ProjectGroupingRef.fromProjectId(task.projectId);
    final key = projectRef.stableKey;

    final group = _projectGroupsByKey.putIfAbsent(
      key,
      () => _ProjectGroup(
        projectRef: projectRef,
        title: projectRef.isInbox ? 'Inbox' : (task.project?.name ?? 'Project'),
      ),
    );

    group.tasks.add(task);
  }
}

class _ProjectGroup {
  _ProjectGroup({
    required this.projectRef,
    required this.title,
  });

  final ProjectGroupingRef projectRef;
  final String title;

  final List<Task> tasks = <Task>[];
}
