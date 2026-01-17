import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';

import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';

sealed class ScopeContextEvent {
  const ScopeContextEvent();
}

final class ScopeContextStarted extends ScopeContextEvent {
  const ScopeContextStarted();
}

final class ScopeContextRetryRequested extends ScopeContextEvent {
  const ScopeContextRetryRequested();
}

sealed class ScopeContextState {
  const ScopeContextState();
}

final class ScopeContextLoading extends ScopeContextState {
  const ScopeContextLoading();
}

final class ScopeContextLoaded extends ScopeContextState {
  const ScopeContextLoaded({
    required this.title,
    required this.taskCount,
    this.projectCount,
  });

  final String title;
  final int taskCount;
  final int? projectCount;
}

final class ScopeContextError extends ScopeContextState {
  const ScopeContextError({required this.message});

  final String message;
}

class ScopeContextBloc extends Bloc<ScopeContextEvent, ScopeContextState> {
  ScopeContextBloc({
    required AnytimeScope scope,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
  }) : _scope = scope,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       super(const ScopeContextLoading()) {
    on<ScopeContextStarted>(_onStarted);
    on<ScopeContextRetryRequested>(_onRetryRequested);

    add(const ScopeContextStarted());
  }

  final AnytimeScope _scope;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;

  StreamSubscription<int>? _taskCountSub;
  StreamSubscription<int>? _projectCountSub;
  StreamSubscription<String>? _titleSub;

  String? _title;
  int? _taskCount;
  int? _projectCount;

  Future<void> _onStarted(
    ScopeContextStarted event,
    Emitter<ScopeContextState> emit,
  ) async {
    await _subscribe(emit);
  }

  Future<void> _onRetryRequested(
    ScopeContextRetryRequested event,
    Emitter<ScopeContextState> emit,
  ) async {
    emit(const ScopeContextLoading());
    await _subscribe(emit);
  }

  Future<void> _subscribe(Emitter<ScopeContextState> emit) async {
    await _taskCountSub?.cancel();
    await _projectCountSub?.cancel();
    await _titleSub?.cancel();

    _title = null;
    _taskCount = null;
    _projectCount = null;

    final taskQuery = _scopeTaskQuery(TaskQuery.incomplete(), _scope);
    _taskCountSub = _taskRepository
        .watchAllCount(taskQuery)
        .listen(
          (count) {
            _taskCount = count;
            _maybeEmitLoaded(emit);
          },
          onError: (Object e, StackTrace s) {
            emit(ScopeContextError(message: e.toString()));
          },
        );

    if (_scope case AnytimeValueScope(:final valueId)) {
      final projectQuery = ProjectQuery(
        filter: QueryFilter<ProjectPredicate>(
          shared: [
            const ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            ProjectValuePredicate(
              operator: ValueOperator.hasAll,
              valueIds: [valueId],
            ),
          ],
        ),
      );

      _projectCountSub = _projectRepository
          .watchAllCount(projectQuery)
          .listen(
            (count) {
              _projectCount = count;
              _maybeEmitLoaded(emit);
            },
            onError: (Object e, StackTrace s) {
              emit(ScopeContextError(message: e.toString()));
            },
          );
    }

    _titleSub = _scopeTitleStream(_scope).listen(
      (title) {
        _title = title;
        _maybeEmitLoaded(emit);
      },
      onError: (Object e, StackTrace s) {
        emit(ScopeContextError(message: e.toString()));
      },
    );
  }

  TaskQuery _scopeTaskQuery(TaskQuery base, AnytimeScope scope) {
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

  Stream<String> _scopeTitleStream(AnytimeScope scope) {
    return switch (scope) {
      AnytimeProjectScope(:final projectId) =>
        _projectRepository
            .watchById(projectId)
            .map((project) => project?.name ?? 'Project'),
      AnytimeValueScope(:final valueId) =>
        _valueRepository
            .watchById(valueId)
            .map((value) => value?.name ?? 'Value'),
    };
  }

  void _maybeEmitLoaded(Emitter<ScopeContextState> emit) {
    final title = _title;
    final taskCount = _taskCount;
    if (title == null || taskCount == null) return;
    if (_scope is AnytimeValueScope && _projectCount == null) return;

    emit(
      ScopeContextLoaded(
        title: title,
        taskCount: taskCount,
        projectCount: _projectCount,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _taskCountSub?.cancel();
    await _projectCountSub?.cancel();
    await _titleSub?.cancel();
    return super.close();
  }
}
