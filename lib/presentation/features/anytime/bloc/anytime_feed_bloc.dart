import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';

import 'package:taskly_bloc/presentation/features/anytime/model/anytime_sort.dart';
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

final class AnytimeFeedSearchQueryChanged extends AnytimeFeedEvent {
  const AnytimeFeedSearchQueryChanged({required this.query});

  final String query;
}

final class AnytimeFeedSortOrderChanged extends AnytimeFeedEvent {
  const AnytimeFeedSortOrderChanged({required this.order});

  final AnytimeSortOrder order;
}

final class AnytimeFeedDueWindowDaysChanged extends AnytimeFeedEvent {
  const AnytimeFeedDueWindowDaysChanged({required this.days});

  final int days;
}

final class AnytimeFeedInboxCollapsedChanged extends AnytimeFeedEvent {
  const AnytimeFeedInboxCollapsedChanged({required this.collapsed});

  final bool collapsed;
}

final class AnytimeFeedValueCollapsedChanged extends AnytimeFeedEvent {
  const AnytimeFeedValueCollapsedChanged({required this.collapsedValueIds});

  final Set<String> collapsedValueIds;
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
    required AnytimeSessionQueryService queryService,
    AnytimeScope? scope,
  }) : _queryService = queryService,
       _scope = scope,
       super(const AnytimeFeedLoading()) {
    on<AnytimeFeedStarted>(_onStarted, transformer: restartable());
    on<AnytimeFeedRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );
    on<AnytimeFeedSearchQueryChanged>(_onSearchQueryChanged);
    on<AnytimeFeedSortOrderChanged>(_onSortOrderChanged);
    on<AnytimeFeedDueWindowDaysChanged>(_onDueWindowDaysChanged);
    on<AnytimeFeedInboxCollapsedChanged>(_onInboxCollapsedChanged);
    on<AnytimeFeedValueCollapsedChanged>(_onValueCollapsedChanged);

    add(const AnytimeFeedStarted());
  }

  final AnytimeSessionQueryService _queryService;
  final AnytimeScope? _scope;

  List<Task> _latestTasks = const <Task>[];
  DateTime _todayDayKeyUtc = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
  String _searchQuery = '';
  AnytimeSortOrder _sortOrder = AnytimeSortOrder.dueSoonest;
  int _dueWindowDays = 7;

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

  void _onSearchQueryChanged(
    AnytimeFeedSearchQueryChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _searchQuery = event.query.trim();
    _emitRows(emit);
  }

  void _onSortOrderChanged(
    AnytimeFeedSortOrderChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _sortOrder = event.order;
    _emitRows(emit);
  }

  void _onDueWindowDaysChanged(
    AnytimeFeedDueWindowDaysChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _dueWindowDays = event.days;
    _emitRows(emit);
  }

  void _onInboxCollapsedChanged(
    AnytimeFeedInboxCollapsedChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _emitRows(emit);
  }

  void _onValueCollapsedChanged(
    AnytimeFeedValueCollapsedChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _emitRows(emit);
  }

  Future<void> _bind(Emitter<AnytimeFeedState> emit) async {
    await emit.onEach<AnytimeBaseSnapshot>(
      _queryService.watchBase(scope: _scope),
      onData: (snapshot) {
        _todayDayKeyUtc = snapshot.todayDayKeyUtc;
        _latestTasks = snapshot.tasks;
        _emitRows(emit);
      },
      onError: (error, stackTrace) {
        emit(AnytimeFeedError(message: error.toString()));
      },
    );
  }

  void _emitRows(Emitter<AnytimeFeedState> emit) {
    try {
      final rows = _mapToRows(_latestTasks);
      emit(AnytimeFeedLoaded(rows: rows));
    } catch (e) {
      emit(AnytimeFeedError(message: e.toString()));
    }
  }

  bool _isStartLater(Task task) {
    final taskStart = task.occurrence?.date ?? task.startDate;
    if (taskStart != null && taskStart.isAfter(_todayDayKeyUtc)) return true;

    final projectStart = task.project?.startDate;
    if (projectStart != null && projectStart.isAfter(_todayDayKeyUtc)) {
      return true;
    }

    return false;
  }

  List<ListRowUiModel> _mapToRows(List<Task> tasks) {
    final aggregates = _aggregateProjects(tasks);
    if (aggregates.isEmpty) return const <ListRowUiModel>[];
    final filtered = aggregates.where(_matchesFilters).toList(growable: false)
      ..sort(_compareProjectGroups);

    return filtered
        .map(
          (pg) => ProjectRowUiModel(
            rowKey: RowKey.v1(
              screen: 'anytime',
              rowType: 'project',
              params: <String, String>{
                'project': pg.projectRef.stableKey,
              },
            ),
            depth: 0,
            project: pg.project,
            taskCount: pg.taskCount,
            completedTaskCount: pg.completedTaskCount,
            dueSoonCount: pg.dueSoonCount,
          ),
        )
        .toList(growable: false);
  }

  List<_ProjectAggregate> _aggregateProjects(List<Task> tasks) {
    final groups = <String, _ProjectAggregate>{};

    final today = DateTime.utc(
      _todayDayKeyUtc.year,
      _todayDayKeyUtc.month,
      _todayDayKeyUtc.day,
    );
    final dueLimit = today.add(
      Duration(days: _dueWindowDays.clamp(1, 30) - 1),
    );

    for (final task in tasks) {
      final projectRef = ProjectGroupingRef.fromProjectId(task.projectId);
      final key = projectRef.stableKey;

      final group = groups.putIfAbsent(
        key,
        () => _ProjectAggregate(
          projectRef: projectRef,
          title: projectRef.isInbox
              ? 'Inbox'
              : (task.project?.name ?? 'Project'),
        ),
      );

      group.project ??= task.project;
      group.tasks.add(task);

      final deadline = task.occurrence?.deadline ?? task.deadlineDate;
      if (deadline != null) {
        final deadlineDay = DateTime.utc(
          deadline.year,
          deadline.month,
          deadline.day,
        );
        group.trackDeadline(deadlineDay);
        if (deadlineDay.isBefore(today)) {
          group.taskOverdueCount += 1;
        } else if (!deadlineDay.isAfter(dueLimit)) {
          group.taskDueSoonCount += 1;
        }
      }

      final isStartLater = _isStartLater(task);
      if (isStartLater) {
        group.hasStartLaterTask = true;
      } else {
        group.hasAvailableTask = true;
      }
    }

    if (_scope == null &&
        !groups.containsKey(ProjectGroupingRef.inbox().stableKey)) {
      groups[ProjectGroupingRef.inbox().stableKey] = _ProjectAggregate(
        projectRef: const ProjectGroupingRef.inbox(),
        title: 'Inbox',
      );
    }

    final aggregates = groups.values.toList(growable: false);
    for (final group in aggregates) {
      final project = group.project;
      if (project == null) {
        group.overdueCount = group.taskOverdueCount;
        group.dueSoonCount = group.taskDueSoonCount;
        continue;
      }

      final deadline = project.deadlineDate;
      if (deadline != null) {
        final deadlineDay = DateTime.utc(
          deadline.year,
          deadline.month,
          deadline.day,
        );
        group.trackDeadline(deadlineDay);
      }

      if (deadline == null || project.completed) {
        group.overdueCount = 0;
        group.dueSoonCount = 0;
        continue;
      }

      final deadlineDay = DateTime.utc(
        deadline.year,
        deadline.month,
        deadline.day,
      );
      if (deadlineDay.isBefore(today)) {
        group.overdueCount = 1;
        group.dueSoonCount = 0;
      } else if (!deadlineDay.isAfter(dueLimit)) {
        group.dueSoonCount = 1;
        group.overdueCount = 0;
      } else {
        group.overdueCount = 0;
        group.dueSoonCount = 0;
      }
    }

    return aggregates;
  }

  bool _matchesFilters(_ProjectAggregate aggregate) {
    if (aggregate.projectRef.isInbox && _noFiltersActive()) {
      return true;
    }

    final search = _searchQuery.toLowerCase().trim();
    if (search.isNotEmpty) {
      final title = aggregate.title.toLowerCase();
      final valueName = aggregate.project?.primaryValue?.name
          .trim()
          .toLowerCase();
      final matchesTitle = title.contains(search);
      final matchesValue = valueName != null && valueName.contains(search);
      if (!matchesTitle && !matchesValue) return false;
    }

    final project = aggregate.project;

    if (_scope case AnytimeValueScope(:final valueId)) {
      if (project?.primaryValue?.id != valueId) return false;
    }

    if (!aggregate.hasAvailableTask) return false;

    return true;
  }

  bool _noFiltersActive() {
    if (_searchQuery.trim().isNotEmpty) return false;
    if (_scope is AnytimeValueScope) return false;
    return true;
  }

  int _compareProjectGroups(_ProjectAggregate a, _ProjectAggregate b) {
    if (a.projectRef.isInbox != b.projectRef.isInbox) {
      return a.projectRef.isInbox ? -1 : 1;
    }

    final aDate = a.sortDeadline(_sortOrder);
    final bDate = b.sortDeadline(_sortOrder);
    final aHasDate = aDate != null;
    final bHasDate = bDate != null;

    if (aHasDate != bHasDate) {
      return aHasDate ? -1 : 1;
    }

    if (aHasDate && bHasDate) {
      final compare = aDate.compareTo(bDate);
      if (compare != 0) {
        return _sortOrder == AnytimeSortOrder.dueSoonest ? compare : -compare;
      }
    }

    final byName = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (byName != 0) return byName;

    return (a.projectRef.projectId ?? '').compareTo(
      b.projectRef.projectId ?? '',
    );
  }
}

class _ProjectAggregate {
  _ProjectAggregate({
    required this.projectRef,
    required this.title,
  });

  final ProjectGroupingRef projectRef;
  final String title;

  Project? project;
  final List<Task> tasks = <Task>[];
  int dueSoonCount = 0;
  int overdueCount = 0;
  int taskDueSoonCount = 0;
  int taskOverdueCount = 0;
  bool hasStartLaterTask = false;
  bool hasAvailableTask = false;
  DateTime? earliestDeadlineUtc;
  DateTime? latestDeadlineUtc;

  void trackDeadline(DateTime deadlineUtc) {
    if (earliestDeadlineUtc == null ||
        deadlineUtc.isBefore(earliestDeadlineUtc!)) {
      earliestDeadlineUtc = deadlineUtc;
    }
    if (latestDeadlineUtc == null || deadlineUtc.isAfter(latestDeadlineUtc!)) {
      latestDeadlineUtc = deadlineUtc;
    }
  }

  DateTime? sortDeadline(AnytimeSortOrder order) {
    return switch (order) {
      AnytimeSortOrder.dueSoonest => earliestDeadlineUtc,
      AnytimeSortOrder.dueLatest => latestDeadlineUtc ?? earliestDeadlineUtc,
    };
  }

  int get taskCount => project?.taskCount ?? tasks.length;

  int get completedTaskCount =>
      project?.completedTaskCount ?? tasks.where((t) => t.completed).length;
}
