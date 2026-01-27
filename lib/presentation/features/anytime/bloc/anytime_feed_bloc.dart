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
  const AnytimeFeedLoaded({
    required this.rows,
    required this.inboxTaskCount,
  });

  final List<ListRowUiModel> rows;
  final int inboxTaskCount;
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
    on<AnytimeFeedInboxCollapsedChanged>(_onInboxCollapsedChanged);

    add(const AnytimeFeedStarted());
  }

  final AnytimeSessionQueryService _queryService;
  final AnytimeScope? _scope;

  List<Project> _latestProjects = const <Project>[];
  int? _inboxTaskCount;
  String _searchQuery = '';
  final AnytimeSortOrder _sortOrder = AnytimeSortOrder.dueSoonest;

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

  void _onInboxCollapsedChanged(
    AnytimeFeedInboxCollapsedChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _emitRows(emit);
  }

  Future<void> _bind(Emitter<AnytimeFeedState> emit) async {
    await emit.onEach<AnytimeProjectsSnapshot>(
      _queryService.watchProjects(scope: _scope),
      onData: (snapshot) {
        _latestProjects = snapshot.projects;
        _inboxTaskCount = snapshot.inboxTaskCount;
        _emitRows(emit);
      },
      onError: (error, stackTrace) {
        emit(AnytimeFeedError(message: error.toString()));
      },
    );
  }

  void _emitRows(Emitter<AnytimeFeedState> emit) {
    try {
      final rows = _mapToRows(_latestProjects);
      emit(
        AnytimeFeedLoaded(
          rows: rows,
          inboxTaskCount: _inboxTaskCount ?? 0,
        ),
      );
    } catch (e) {
      emit(AnytimeFeedError(message: e.toString()));
    }
  }

  List<ListRowUiModel> _mapToRows(List<Project> projects) {
    final aggregates = _aggregateProjects(projects);
    final filtered = aggregates.where(_matchesFilters).toList(growable: false)
      ..sort(_compareProjectGroupsWithValues);

    final rows = <ListRowUiModel>[];

    for (final aggregate in filtered) {
      rows.add(
        ProjectRowUiModel(
          rowKey: RowKey.v1(
            screen: 'anytime',
            rowType: 'project',
            params: <String, String>{
              'project': aggregate.projectRef.stableKey,
            },
          ),
          depth: 0,
          project: aggregate.project,
          taskCount: aggregate.taskCount,
          completedTaskCount: aggregate.completedTaskCount,
          dueSoonCount: aggregate.dueSoonCount,
        ),
      );
    }

    return rows;
  }

  List<_ProjectAggregate> _aggregateProjects(
    List<Project> projects,
  ) {
    return projects
        .map(
          (project) {
            final aggregate = _ProjectAggregate(
              projectRef: ProjectGroupingRef.fromProjectId(project.id),
              title: project.name,
              project: project,
              taskCount: project.taskCount,
              completedTaskCount: project.completedTaskCount,
              dueSoonCount: 0,
            );

            final deadline = project.deadlineDate;
            if (deadline != null) {
              aggregate.trackDeadline(
                DateTime.utc(deadline.year, deadline.month, deadline.day),
              );
            }

            return aggregate;
          },
        )
        .toList(growable: true);
  }

  bool _matchesFilters(_ProjectAggregate aggregate) {
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

    return true;
  }

  int _compareProjectGroups(_ProjectAggregate a, _ProjectAggregate b) {
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

  int _compareProjectGroupsWithValues(
    _ProjectAggregate a,
    _ProjectAggregate b,
  ) {
    final aValue = a.project?.primaryValue;
    final bValue = b.project?.primaryValue;
    final rankA = _valuePriorityRank(aValue?.priority ?? ValuePriority.medium);
    final rankB = _valuePriorityRank(bValue?.priority ?? ValuePriority.medium);
    if (rankA != rankB) return rankA.compareTo(rankB);

    final aValueName = (aValue?.name ?? '').toLowerCase();
    final bValueName = (bValue?.name ?? '').toLowerCase();
    final byValueName = aValueName.compareTo(bValueName);
    if (byValueName != 0) return byValueName;

    return _compareProjectGroups(a, b);
  }
}

class _ProjectAggregate {
  _ProjectAggregate({
    required this.projectRef,
    required this.title,
    required this.project,
    required this.taskCount,
    required this.completedTaskCount,
    required this.dueSoonCount,
  });

  final ProjectGroupingRef projectRef;
  final String title;
  final Project? project;
  final int taskCount;
  final int completedTaskCount;
  final int dueSoonCount;
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
}

int _valuePriorityRank(ValuePriority priority) {
  return switch (priority) {
    ValuePriority.high => 0,
    ValuePriority.medium => 1,
    ValuePriority.low => 2,
  };
}
