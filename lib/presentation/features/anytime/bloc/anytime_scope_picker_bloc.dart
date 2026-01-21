import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';

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
    required ValueRepositoryContract valueRepository,
    required ProjectRepositoryContract projectRepository,
  }) : _valueRepository = valueRepository,
       _projectRepository = projectRepository,
       super(const AnytimeScopePickerLoading()) {
    on<AnytimeScopePickerStarted>(_onStarted);
    on<AnytimeScopePickerRetryRequested>(_onRetryRequested);

    add(const AnytimeScopePickerStarted());
  }

  final ValueRepositoryContract _valueRepository;
  final ProjectRepositoryContract _projectRepository;

  StreamSubscription<List<Value>>? _valuesSub;
  StreamSubscription<List<Project>>? _projectsSub;

  List<Value> _latestValues = const <Value>[];
  List<Project> _latestProjects = const <Project>[];

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
    await _valuesSub?.cancel();
    await _projectsSub?.cancel();

    _valuesSub = _valueRepository.watchAll().listen(
      (values) {
        _latestValues = values.toList(growable: false)..sort(_compareValues);
        emit(
          AnytimeScopePickerLoaded(
            values: _latestValues,
            projects: _latestProjects,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(AnytimeScopePickerError(message: error.toString()));
      },
    );

    _projectsSub = _projectRepository.watchAll().listen(
      (projects) {
        _latestProjects = projects.toList(growable: false)
          ..sort(_compareProjects);
        emit(
          AnytimeScopePickerLoaded(
            values: _latestValues,
            projects: _latestProjects,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(AnytimeScopePickerError(message: error.toString()));
      },
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

  @override
  Future<void> close() async {
    await _valuesSub?.cancel();
    await _projectsSub?.cancel();
    return super.close();
  }
}
