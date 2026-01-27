import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

sealed class AnytimeScopePickerEvent {
  const AnytimeScopePickerEvent();
}

final class AnytimeScopePickerStarted extends AnytimeScopePickerEvent {
  const AnytimeScopePickerStarted();
}

final class AnytimeScopePickerRetryRequested extends AnytimeScopePickerEvent {
  const AnytimeScopePickerRetryRequested();
}

sealed class AnytimeScopePickerState {
  const AnytimeScopePickerState();
}

final class AnytimeScopePickerLoading extends AnytimeScopePickerState {
  const AnytimeScopePickerLoading();
}

final class AnytimeScopePickerError extends AnytimeScopePickerState {
  const AnytimeScopePickerError({required this.message});

  final String message;
}

final class AnytimeScopePickerLoaded extends AnytimeScopePickerState {
  const AnytimeScopePickerLoaded({
    required this.values,
    required this.projects,
  });

  final List<Value> values;
  final List<Project> projects;
}

class AnytimeScopePickerBloc
    extends Bloc<AnytimeScopePickerEvent, AnytimeScopePickerState> {
  AnytimeScopePickerBloc({
    required SessionSharedDataService sharedDataService,
  }) : _sharedDataService = sharedDataService,
       super(const AnytimeScopePickerLoading()) {
    on<AnytimeScopePickerStarted>(_onStarted, transformer: restartable());
    on<AnytimeScopePickerRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );

    add(const AnytimeScopePickerStarted());
  }

  final SessionSharedDataService _sharedDataService;

  Future<void> _onStarted(
    AnytimeScopePickerStarted event,
    Emitter<AnytimeScopePickerState> emit,
  ) async {
    await _bind(emit);
  }

  Future<void> _onRetryRequested(
    AnytimeScopePickerRetryRequested event,
    Emitter<AnytimeScopePickerState> emit,
  ) async {
    emit(const AnytimeScopePickerLoading());
    await _bind(emit);
  }

  Future<void> _bind(Emitter<AnytimeScopePickerState> emit) async {
    final values$ = _sharedDataService.watchValues().map(
      (values) => values.toList(growable: false)..sort(_compareValues),
    );
    final projects$ = _sharedDataService.watchAllProjects().map(
      (projects) => projects.toList(growable: false)..sort(_compareProjects),
    );

    final combined$ =
        Rx.combineLatest2<List<Value>, List<Project>, AnytimeScopePickerState>(
          values$,
          projects$,
          (values, projects) =>
              AnytimeScopePickerLoaded(values: values, projects: projects),
        );

    await emit.forEach<AnytimeScopePickerState>(
      combined$,
      onData: (state) => state,
      onError: (error, stackTrace) =>
          AnytimeScopePickerError(message: error.toString()),
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
