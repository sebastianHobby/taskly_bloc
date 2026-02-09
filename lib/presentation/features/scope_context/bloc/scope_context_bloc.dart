import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';

import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';

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

enum ScopeContextTitleKind {
  project,
  value,
}

class ScopeContextTitle {
  const ScopeContextTitle({required this.kind, this.name});

  final ScopeContextTitleKind kind;
  final String? name;
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

  final ScopeContextTitle title;
  final int taskCount;
  final int? projectCount;
}

final class ScopeContextError extends ScopeContextState {
  const ScopeContextError({this.error});

  final Object? error;
}

class ScopeContextBloc extends Bloc<ScopeContextEvent, ScopeContextState> {
  ScopeContextBloc({
    required ProjectsScope scope,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
  }) : _scope = scope,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       super(const ScopeContextLoading()) {
    on<ScopeContextStarted>(_onStarted, transformer: restartable());
    on<ScopeContextRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );

    add(const ScopeContextStarted());
  }

  final ProjectsScope _scope;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;

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
    final taskQuery = _scopeTaskQuery(TaskQuery.incomplete(), _scope);
    final taskCount$ = _taskRepository.watchAllCount(taskQuery);
    final title$ = _scopeTitleStream(_scope);

    final Stream<ScopeContextState> combined$ = switch (_scope) {
      ProjectsValueScope(:final valueId) => () {
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

        final projectCount$ = _projectRepository.watchAllCount(projectQuery);

        return Rx.combineLatest3<
          ScopeContextTitle,
          int,
          int,
          ScopeContextState
        >(
          title$,
          taskCount$,
          projectCount$,
          (title, taskCount, projectCount) => ScopeContextLoaded(
            title: title,
            taskCount: taskCount,
            projectCount: projectCount,
          ),
        );
      }(),
      _ => Rx.combineLatest2<ScopeContextTitle, int, ScopeContextState>(
        title$,
        taskCount$,
        (title, taskCount) => ScopeContextLoaded(
          title: title,
          taskCount: taskCount,
        ),
      ),
    };

    await emit.forEach<ScopeContextState>(
      combined$,
      onData: (state) => state,
      onError: (error, stackTrace) => ScopeContextError(error: error),
    );
  }

  TaskQuery _scopeTaskQuery(TaskQuery base, ProjectsScope scope) {
    return switch (scope) {
      ProjectsProjectScope(:final projectId) => base.withAdditionalPredicates([
        TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: projectId,
        ),
      ]),
      ProjectsValueScope(:final valueId) => base.withAdditionalPredicates([
        TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: [valueId],
          includeInherited: true,
        ),
      ]),
    };
  }

  Stream<ScopeContextTitle> _scopeTitleStream(ProjectsScope scope) {
    return switch (scope) {
      ProjectsProjectScope(:final projectId) =>
        _projectRepository
            .watchById(projectId)
            .map(
              (project) => ScopeContextTitle(
                kind: ScopeContextTitleKind.project,
                name: project?.name,
              ),
            ),
      ProjectsValueScope(:final valueId) =>
        _valueRepository
            .watchById(valueId)
            .map(
              (value) => ScopeContextTitle(
                kind: ScopeContextTitleKind.value,
                name: value?.name,
              ),
            ),
    };
  }
}
