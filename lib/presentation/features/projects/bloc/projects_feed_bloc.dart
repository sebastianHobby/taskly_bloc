import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/features/projects/services/projects_session_query_service.dart';

import 'package:taskly_bloc/presentation/features/projects/model/projects_sort.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';

sealed class ProjectsFeedEvent {
  const ProjectsFeedEvent();
}

final class ProjectsFeedStarted extends ProjectsFeedEvent {
  const ProjectsFeedStarted();
}

final class ProjectsFeedRetryRequested extends ProjectsFeedEvent {
  const ProjectsFeedRetryRequested();
}

final class ProjectsFeedSearchQueryChanged extends ProjectsFeedEvent {
  const ProjectsFeedSearchQueryChanged({required this.query});

  final String query;
}

final class ProjectsFeedInboxCollapsedChanged extends ProjectsFeedEvent {
  const ProjectsFeedInboxCollapsedChanged({required this.collapsed});

  final bool collapsed;
}

final class ProjectsFeedSortOrderChanged extends ProjectsFeedEvent {
  const ProjectsFeedSortOrderChanged({required this.sortOrder});

  final ProjectsSortOrder sortOrder;
}

sealed class ProjectsFeedState {
  const ProjectsFeedState();
}

final class ProjectsFeedLoading extends ProjectsFeedState {
  const ProjectsFeedLoading();
}

final class ProjectsFeedLoaded extends ProjectsFeedState {
  const ProjectsFeedLoaded({
    required this.rows,
    required this.inboxTaskCount,
    required this.values,
    required this.ratings,
  });

  final List<ListRowUiModel> rows;
  final int inboxTaskCount;
  final List<Value> values;
  final List<ValueWeeklyRating> ratings;
}

final class ProjectsFeedError extends ProjectsFeedState {
  const ProjectsFeedError({required this.message});

  final String message;
}

class ProjectsFeedBloc extends Bloc<ProjectsFeedEvent, ProjectsFeedState> {
  ProjectsFeedBloc({
    required ProjectsSessionQueryService queryService,
    ProjectsScope? scope,
  }) : _queryService = queryService,
       _scope = scope,
       super(const ProjectsFeedLoading()) {
    on<ProjectsFeedStarted>(_onStarted, transformer: restartable());
    on<ProjectsFeedRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );
    on<ProjectsFeedSearchQueryChanged>(_onSearchQueryChanged);
    on<ProjectsFeedInboxCollapsedChanged>(_onInboxCollapsedChanged);
    on<ProjectsFeedSortOrderChanged>(_onSortOrderChanged);

    add(const ProjectsFeedStarted());
  }

  final ProjectsSessionQueryService _queryService;
  final ProjectsScope? _scope;

  List<Project> _latestProjects = const <Project>[];
  int? _inboxTaskCount;
  List<Value> _latestValues = const <Value>[];
  List<ValueWeeklyRating> _latestRatings = const <ValueWeeklyRating>[];
  String _searchQuery = '';
  ProjectsSortOrder _sortOrder = ProjectsSortOrder.recentlyUpdated;

  Future<void> _onStarted(
    ProjectsFeedStarted event,
    Emitter<ProjectsFeedState> emit,
  ) async {
    await _bind(emit);
  }

  Future<void> _onRetryRequested(
    ProjectsFeedRetryRequested event,
    Emitter<ProjectsFeedState> emit,
  ) async {
    emit(const ProjectsFeedLoading());
    await _bind(emit);
  }

  void _onSearchQueryChanged(
    ProjectsFeedSearchQueryChanged event,
    Emitter<ProjectsFeedState> emit,
  ) {
    _searchQuery = event.query.trim();
    _emitRows(emit);
  }

  void _onInboxCollapsedChanged(
    ProjectsFeedInboxCollapsedChanged event,
    Emitter<ProjectsFeedState> emit,
  ) {
    _emitRows(emit);
  }

  void _onSortOrderChanged(
    ProjectsFeedSortOrderChanged event,
    Emitter<ProjectsFeedState> emit,
  ) {
    if (_sortOrder == event.sortOrder) return;
    _sortOrder = event.sortOrder;
    _emitRows(emit);
  }

  Future<void> _bind(Emitter<ProjectsFeedState> emit) async {
    await emit.onEach<ProjectsSnapshot>(
      _queryService.watchProjects(scope: _scope),
      onData: (snapshot) {
        _latestProjects = snapshot.projects;
        _inboxTaskCount = snapshot.inboxTaskCount;
        _latestValues = snapshot.values;
        _latestRatings = snapshot.ratings;
        _emitRows(emit);
      },
      onError: (error, stackTrace) {
        emit(ProjectsFeedError(message: error.toString()));
      },
    );
  }

  void _emitRows(Emitter<ProjectsFeedState> emit) {
    try {
      final rows = _mapToRows(
        _latestProjects,
      );
      emit(
        ProjectsFeedLoaded(
          rows: rows,
          inboxTaskCount: _inboxTaskCount ?? 0,
          values: _latestValues,
          ratings: _latestRatings,
        ),
      );
    } catch (e) {
      emit(ProjectsFeedError(message: e.toString()));
    }
  }

  List<ListRowUiModel> _mapToRows(
    List<Project> projects,
  ) {
    final aggregates = _aggregateProjects(projects);
    final filtered = aggregates.where(_matchesFilters).toList(growable: false)
      ..sort(_compareProjectGroupsWithValues);

    final rows = <ListRowUiModel>[];

    for (final aggregate in filtered) {
      rows.add(
        ProjectRowUiModel(
          rowKey: RowKey.v1(
            screen: 'projects',
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
    return switch (_sortOrder) {
      ProjectsSortOrder.recentlyUpdated => _compareByUpdated(a, b),
      ProjectsSortOrder.alphabetical => _compareByName(a, b),
      ProjectsSortOrder.priority => _compareByPriority(a, b),
      ProjectsSortOrder.dueDate => _compareByDueDate(a, b),
    };
  }

  int _compareProjectGroupsWithValues(
    _ProjectAggregate a,
    _ProjectAggregate b,
  ) {
    final aInbox = a.projectRef.isInbox;
    final bInbox = b.projectRef.isInbox;
    if (aInbox != bInbox) {
      return aInbox ? -1 : 1;
    }

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
}

int _compareByUpdated(_ProjectAggregate a, _ProjectAggregate b) {
  final aUpdated = a.project?.updatedAt;
  final bUpdated = b.project?.updatedAt;
  if (aUpdated != null && bUpdated != null) {
    final byUpdated = bUpdated.compareTo(aUpdated);
    if (byUpdated != 0) return byUpdated;
  } else if (aUpdated != null || bUpdated != null) {
    return aUpdated != null ? -1 : 1;
  }
  return _compareByName(a, b);
}

int _compareByName(_ProjectAggregate a, _ProjectAggregate b) {
  final byName = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  if (byName != 0) return byName;
  return (a.projectRef.projectId ?? '').compareTo(
    b.projectRef.projectId ?? '',
  );
}

int _compareByPriority(_ProjectAggregate a, _ProjectAggregate b) {
  final aPriority = a.project?.priority ?? 999;
  final bPriority = b.project?.priority ?? 999;
  final byPriority = aPriority.compareTo(bPriority);
  if (byPriority != 0) return byPriority;
  return _compareByName(a, b);
}

int _compareByDueDate(_ProjectAggregate a, _ProjectAggregate b) {
  final aDate = a.earliestDeadlineUtc;
  final bDate = b.earliestDeadlineUtc;
  if (aDate != null && bDate != null) {
    final compare = aDate.compareTo(bDate);
    if (compare != 0) return compare;
  } else if (aDate != null || bDate != null) {
    return aDate != null ? -1 : 1;
  }
  return _compareByName(a, b);
}
