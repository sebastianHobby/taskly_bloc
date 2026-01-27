import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

sealed class ProjectPickerEvent {
  const ProjectPickerEvent();
}

final class ProjectPickerStarted extends ProjectPickerEvent {
  const ProjectPickerStarted();
}

final class ProjectPickerSearchChanged extends ProjectPickerEvent {
  const ProjectPickerSearchChanged({required this.query});

  final String query;
}

final class ProjectPickerRetryRequested extends ProjectPickerEvent {
  const ProjectPickerRetryRequested();
}

final class ProjectPickerState {
  const ProjectPickerState({
    required this.query,
    required this.isLoading,
    required this.allProjects,
    required this.visibleProjects,
    required this.hasLoadError,
  });

  const ProjectPickerState.initial()
    : query = '',
      isLoading = true,
      allProjects = const <Project>[],
      visibleProjects = const <Project>[],
      hasLoadError = false;

  final String query;
  final bool isLoading;
  final List<Project> allProjects;
  final List<Project> visibleProjects;
  final bool hasLoadError;

  ProjectPickerState copyWith({
    String? query,
    bool? isLoading,
    List<Project>? allProjects,
    List<Project>? visibleProjects,
    bool? hasLoadError,
  }) {
    return ProjectPickerState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      allProjects: allProjects ?? this.allProjects,
      visibleProjects: visibleProjects ?? this.visibleProjects,
      hasLoadError: hasLoadError ?? this.hasLoadError,
    );
  }
}

class ProjectPickerBloc extends Bloc<ProjectPickerEvent, ProjectPickerState> {
  ProjectPickerBloc({required SessionSharedDataService sharedDataService})
    : _sharedDataService = sharedDataService,
      super(const ProjectPickerState.initial()) {
    on<ProjectPickerStarted>(_onStarted, transformer: restartable());
    on<ProjectPickerSearchChanged>(_onSearchChanged);
    on<ProjectPickerRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );
  }

  final SessionSharedDataService _sharedDataService;

  Future<void> _onStarted(
    ProjectPickerStarted event,
    Emitter<ProjectPickerState> emit,
  ) async {
    await _subscribe(emit, showLoading: true);
  }

  Future<void> _onRetryRequested(
    ProjectPickerRetryRequested event,
    Emitter<ProjectPickerState> emit,
  ) async {
    await _subscribe(emit, showLoading: state.allProjects.isEmpty);
  }

  Future<void> _subscribe(
    Emitter<ProjectPickerState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(state.copyWith(isLoading: true, hasLoadError: false));
    } else {
      emit(state.copyWith(hasLoadError: false));
    }

    await emit.forEach<List<Project>>(
      _sharedDataService.watchAllProjects(),
      onData: (projects) {
        final sorted = projects.toList()..sort(_compareProjects);
        final visible = _applyQuery(sorted, state.query);
        return state.copyWith(
          isLoading: false,
          hasLoadError: false,
          allProjects: sorted,
          visibleProjects: visible,
        );
      },
      onError: (error, stackTrace) =>
          state.copyWith(isLoading: false, hasLoadError: true),
    );
  }

  void _onSearchChanged(
    ProjectPickerSearchChanged event,
    Emitter<ProjectPickerState> emit,
  ) {
    final query = event.query;
    final visible = _applyQuery(state.allProjects, query);
    emit(state.copyWith(query: query, visibleProjects: visible));
  }

  List<Project> _applyQuery(List<Project> projects, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return projects;

    final filtered = projects
        .where((p) => p.name.toLowerCase().contains(normalized))
        .toList();
    filtered.sort(_compareProjects);
    return filtered;
  }

  int _compareProjects(Project a, Project b) {
    final nameA = a.name.toLowerCase();
    final nameB = b.name.toLowerCase();
    final nameCmp = nameA.compareTo(nameB);
    if (nameCmp != 0) return nameCmp;
    return a.id.compareTo(b.id);
  }
}
