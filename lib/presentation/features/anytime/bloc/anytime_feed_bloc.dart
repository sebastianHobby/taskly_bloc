import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';

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

final class AnytimeFeedFilterDueSoonChanged extends AnytimeFeedEvent {
  const AnytimeFeedFilterDueSoonChanged({required this.enabled});

  final bool enabled;
}

final class AnytimeFeedFilterOverdueChanged extends AnytimeFeedEvent {
  const AnytimeFeedFilterOverdueChanged({required this.enabled});

  final bool enabled;
}

final class AnytimeFeedFilterPriorityChanged extends AnytimeFeedEvent {
  const AnytimeFeedFilterPriorityChanged({required this.enabled});

  final bool enabled;
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
    on<AnytimeFeedFocusOnlyChanged>(_onFocusOnlyChanged);
    on<AnytimeFeedShowStartLaterItemsChanged>(_onShowStartLaterItemsChanged);
    on<AnytimeFeedSearchQueryChanged>(_onSearchQueryChanged);
    on<AnytimeFeedFilterDueSoonChanged>(_onFilterDueSoonChanged);
    on<AnytimeFeedFilterOverdueChanged>(_onFilterOverdueChanged);
    on<AnytimeFeedFilterPriorityChanged>(_onFilterPriorityChanged);
    on<AnytimeFeedDueWindowDaysChanged>(_onDueWindowDaysChanged);
    on<AnytimeFeedInboxCollapsedChanged>(_onInboxCollapsedChanged);
    on<AnytimeFeedValueCollapsedChanged>(_onValueCollapsedChanged);

    add(const AnytimeFeedStarted());
  }

  final AnytimeSessionQueryService _queryService;
  final AnytimeScope? _scope;

  List<Task> _latestTasks = const <Task>[];
  Set<String> _todaySelectedTaskIds = const <String>{};
  DateTime _todayDayKeyUtc = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
  bool _focusOnly = false;
  bool _showStartLaterItems = false;
  bool _inboxCollapsed = false;
  Set<String> _collapsedValueIds = const <String>{};
  String _searchQuery = '';
  bool _filterDueSoon = false;
  bool _filterOverdue = false;
  bool _filterPriority = false;
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

  void _onFilterDueSoonChanged(
    AnytimeFeedFilterDueSoonChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _filterDueSoon = event.enabled;
    _emitRows(emit);
  }

  void _onFilterOverdueChanged(
    AnytimeFeedFilterOverdueChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _filterOverdue = event.enabled;
    _emitRows(emit);
  }

  void _onFilterPriorityChanged(
    AnytimeFeedFilterPriorityChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _filterPriority = event.enabled;
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
    _inboxCollapsed = event.collapsed;
    _emitRows(emit);
  }

  void _onValueCollapsedChanged(
    AnytimeFeedValueCollapsedChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _collapsedValueIds = event.collapsedValueIds;
    _emitRows(emit);
  }

  Future<void> _bind(Emitter<AnytimeFeedState> emit) async {
    await emit.onEach<AnytimeBaseSnapshot>(
      _queryService.watchBase(scope: _scope),
      onData: (snapshot) {
        _todayDayKeyUtc = snapshot.todayDayKeyUtc;
        _latestTasks = snapshot.tasks;
        _todaySelectedTaskIds = snapshot.todaySelectedTaskIds;
        _emitRows(emit);
      },
      onError: (error, stackTrace) {
        emit(AnytimeFeedError(message: error.toString()));
      },
    );
  }

  void _emitRows(Emitter<AnytimeFeedState> emit) {
    try {
      final tasks = _latestTasks
          .where((t) => !_focusOnly || _todaySelectedTaskIds.contains(t.id))
          .where((t) => _showStartLaterItems || !_isStartLater(t))
          .toList(growable: false);

      final rows = _mapToRows(tasks);
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
    if (tasks.isEmpty) return const <ListRowUiModel>[];

    final aggregates = _aggregateProjects(tasks);
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

    final today = DateTime(
      _todayDayKeyUtc.year,
      _todayDayKeyUtc.month,
      _todayDayKeyUtc.day,
      isUtc: _todayDayKeyUtc.isUtc,
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
          title: projectRef.isInbox ? 'Inbox' : (task.project?.name ?? 'Project'),
        ),
      );

      group.project ??= task.project;
      group.tasks.add(task);

      final deadline = task.occurrence?.deadline ?? task.deadlineDate;
      if (deadline != null) {
        final deadlineDay = DateTime(
          deadline.year,
          deadline.month,
          deadline.day,
          isUtc: deadline.isUtc,
        );
        if (deadlineDay.isBefore(today)) {
          group.overdueCount += 1;
        } else if (!deadlineDay.isAfter(dueLimit)) {
          group.dueSoonCount += 1;
        }
      }
    }

    return groups.values.toList(growable: false);
  }

  bool _matchesFilters(_ProjectAggregate aggregate) {
    final search = _searchQuery.toLowerCase().trim();
    if (search.isNotEmpty) {
      final title = aggregate.title.toLowerCase();
      final valueName =
          aggregate.project?.primaryValue?.name.trim().toLowerCase();
      final matchesTitle = title.contains(search);
      final matchesValue =
          valueName != null && valueName.contains(search);
      if (!matchesTitle && !matchesValue) return false;
    }

    if (_filterPriority) {
      if (aggregate.project?.priority != 1) return false;
    }

    if (_filterOverdue && aggregate.overdueCount <= 0) return false;

    if (_filterDueSoon && aggregate.dueSoonCount <= 0) return false;

    return true;
  }

  int _compareProjectGroups(_ProjectAggregate a, _ProjectAggregate b) {
    if (a.projectRef.isInbox != b.projectRef.isInbox) {
      return a.projectRef.isInbox ? -1 : 1;
    }

    final aOverdue = a.overdueCount > 0;
    final bOverdue = b.overdueCount > 0;
    if (aOverdue != bOverdue) return aOverdue ? -1 : 1;

    final aDueSoon = a.dueSoonCount > 0;
    final bDueSoon = b.dueSoonCount > 0;
    if (aDueSoon != bDueSoon) return aDueSoon ? -1 : 1;

    final ap = a.project?.priority ?? 99;
    final bp = b.project?.priority ?? 99;
    if (ap != bp) return ap.compareTo(bp);

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

  int get taskCount => project?.taskCount ?? tasks.length;

  int get completedTaskCount =>
      project?.completedTaskCount ?? tasks.where((t) => t.completed).length;
}
