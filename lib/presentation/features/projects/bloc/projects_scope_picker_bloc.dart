import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

sealed class ProjectsScopePickerEvent {
  const ProjectsScopePickerEvent();
}

final class ProjectsScopePickerStarted extends ProjectsScopePickerEvent {
  const ProjectsScopePickerStarted();
}

final class ProjectsScopePickerRetryRequested extends ProjectsScopePickerEvent {
  const ProjectsScopePickerRetryRequested();
}

sealed class ProjectsScopePickerState {
  const ProjectsScopePickerState();
}

final class ProjectsScopePickerLoading extends ProjectsScopePickerState {
  const ProjectsScopePickerLoading();
}

final class ProjectsScopePickerError extends ProjectsScopePickerState {
  const ProjectsScopePickerError({required this.message});

  final String message;
}

final class ProjectsScopePickerLoaded extends ProjectsScopePickerState {
  const ProjectsScopePickerLoaded({
    required this.values,
    required this.projects,
  });

  final List<Value> values;
  final List<Project> projects;
}

class ProjectsScopePickerBloc
    extends Bloc<ProjectsScopePickerEvent, ProjectsScopePickerState> {
  ProjectsScopePickerBloc({
    required SessionSharedDataService sharedDataService,
  }) : _sharedDataService = sharedDataService,
       super(const ProjectsScopePickerLoading()) {
    on<ProjectsScopePickerStarted>(_onStarted, transformer: restartable());
    on<ProjectsScopePickerRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );

    add(const ProjectsScopePickerStarted());
  }

  final SessionSharedDataService _sharedDataService;

  Future<void> _onStarted(
    ProjectsScopePickerStarted event,
    Emitter<ProjectsScopePickerState> emit,
  ) async {
    await _bind(emit);
  }

  Future<void> _onRetryRequested(
    ProjectsScopePickerRetryRequested event,
    Emitter<ProjectsScopePickerState> emit,
  ) async {
    emit(const ProjectsScopePickerLoading());
    await _bind(emit);
  }

  Future<void> _bind(Emitter<ProjectsScopePickerState> emit) async {
    final values$ = _sharedDataService.watchValues().map(
      (values) => values.toList(growable: false)..sort(_compareValues),
    );
    final projects$ = _sharedDataService.watchAllProjects().map(
      (projects) => projects.toList(growable: false)..sort(_compareProjects),
    );

    final combined$ =
        Rx.combineLatest2<List<Value>, List<Project>, ProjectsScopePickerState>(
          values$,
          projects$,
          (values, projects) =>
              ProjectsScopePickerLoaded(values: values, projects: projects),
        );

    await emit.forEach<ProjectsScopePickerState>(
      combined$,
      onData: (state) => state,
      onError: (error, stackTrace) =>
          ProjectsScopePickerError(message: error.toString()),
    );
  }

  int _compareValues(Value a, Value b) {
    final ap = a.priority;
    final bp = b.priority;
    final byP = _priorityRank(ap).compareTo(_priorityRank(bp));
    if (byP != 0) return byP;

    final an = a.name.trim().toLowerCase();
    final bn = b.name.trim().toLowerCase();
    final byN = an.compareTo(bn);
    if (byN != 0) return byN;

    return a.id.compareTo(b.id);
  }

  int _priorityRank(ValuePriority p) {
    return switch (p) {
      ValuePriority.high => 0,
      ValuePriority.medium => 1,
      ValuePriority.low => 2,
    };
  }

  int _compareProjects(Project a, Project b) {
    final an = a.name.trim().toLowerCase();
    final bn = b.name.trim().toLowerCase();
    final byN = an.compareTo(bn);
    if (byN != 0) return byN;

    return a.id.compareTo(b.id);
  }
}
