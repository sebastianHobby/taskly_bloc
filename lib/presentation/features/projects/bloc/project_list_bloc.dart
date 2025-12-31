import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/shared/mixins/list_bloc_mixin.dart';
import 'package:taskly_bloc/presentation/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
part 'project_list_bloc.freezed.dart';

@freezed
sealed class ProjectOverviewEvent with _$ProjectOverviewEvent {
  const factory ProjectOverviewEvent.subscriptionRequested() =
      ProjectOverviewSubscriptionRequested;
  const factory ProjectOverviewEvent.toggleProjectCompletion({
    required Project project,
  }) = ProjectOverviewToggleProjectCompletion;
  const factory ProjectOverviewEvent.sortChanged({
    required SortPreferences preferences,
  }) = ProjectOverviewSortChanged;
  const factory ProjectOverviewEvent.displaySettingsChanged({
    required PageDisplaySettings settings,
  }) = ProjectOverviewDisplaySettingsChanged;
  const factory ProjectOverviewEvent.taskCountsUpdated({
    required Map<String, ProjectTaskCounts> taskCounts,
  }) = ProjectOverviewTaskCountsUpdated;
  const factory ProjectOverviewEvent.deleteProject({
    required Project project,
  }) = ProjectOverviewDeleteProject;
}

@freezed
sealed class ProjectOverviewState with _$ProjectOverviewState {
  const factory ProjectOverviewState.initial() = ProjectOverviewInitial;
  const factory ProjectOverviewState.loading() = ProjectOverviewLoading;
  const factory ProjectOverviewState.loaded({
    required List<Project> projects,
    @Default({}) Map<String, ProjectTaskCounts> taskCounts,
  }) = ProjectOverviewLoaded;
  const factory ProjectOverviewState.error({required Object error}) =
      ProjectOverviewError;
}

class ProjectOverviewBloc
    extends Bloc<ProjectOverviewEvent, ProjectOverviewState>
    with ListBlocMixin<ProjectOverviewEvent, ProjectOverviewState, Project> {
  ProjectOverviewBloc({
    required ProjectRepositoryContract projectRepository,
    TaskRepositoryContract? taskRepository,
    bool withRelated = false,
    SettingsRepositoryContract? settingsRepository,
    PageKey? pageKey,
  }) : _projectRepository = projectRepository,
       _taskRepository = taskRepository,
       _withRelated = withRelated,
       _settingsRepository = settingsRepository,
       _pageKey = pageKey,
       _sortPreferences = const SortPreferences(),
       super(const ProjectOverviewInitial()) {
    on<ProjectOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<ProjectOverviewToggleProjectCompletion>(_onToggleCompletion);
    on<ProjectOverviewSortChanged>(_onSortChanged);
    on<ProjectOverviewDisplaySettingsChanged>(_onDisplaySettingsChanged);
    on<ProjectOverviewTaskCountsUpdated>(_onTaskCountsUpdated);
    on<ProjectOverviewDeleteProject>(_onDeleteProject);
  }

  final ProjectRepositoryContract _projectRepository;
  final TaskRepositoryContract? _taskRepository;
  final bool _withRelated;
  final SettingsRepositoryContract? _settingsRepository;
  final PageKey? _pageKey;
  SortPreferences _sortPreferences;
  StreamSubscription<Map<String, ProjectTaskCounts>>? _taskCountsSubscription;

  SortPreferences get currentSortPreferences => _sortPreferences;

  /// Load display settings for this page.
  Future<PageDisplaySettings> loadDisplaySettings() async {
    if (_settingsRepository == null || _pageKey == null) {
      return const PageDisplaySettings();
    }
    return _settingsRepository.loadPageDisplaySettings(_pageKey);
  }

  // ListBlocMixin implementation
  @override
  ProjectOverviewState createLoadingState() => const ProjectOverviewLoading();

  @override
  ProjectOverviewState createErrorState(Object error) =>
      ProjectOverviewError(error: error);

  @override
  ProjectOverviewState createLoadedState(List<Project> items) {
    final currentCounts = state.maybeWhen(
      loaded: (_, taskCounts) => taskCounts,
      orElse: () => <String, ProjectTaskCounts>{},
    );
    return ProjectOverviewLoaded(projects: items, taskCounts: currentCounts);
  }

  List<Project> _sortProjects(List<Project> projects) {
    List<Project> compareSorted(List<Project> source, List<SortCriterion> c) {
      int compareByCriterion(Project a, Project b, SortCriterion criterion) {
        final modifier = criterion.direction == SortDirection.ascending
            ? 1
            : -1;
        final value = switch (criterion.field) {
          SortField.name => compareAsciiLowerCase(a.name, b.name),
          SortField.startDate => compareNullableDate(a.startDate, b.startDate),
          SortField.deadlineDate => compareNullableDate(
            a.deadlineDate,
            b.deadlineDate,
          ),
          SortField.createdDate => compareNullableDate(
            a.createdAt,
            b.createdAt,
          ),
          SortField.updatedDate => compareNullableDate(
            a.updatedAt,
            b.updatedAt,
          ),
        };
        return value * modifier;
      }

      final sorted = [...source];
      sorted.sort((a, b) {
        for (final criterion in c) {
          final cmp = compareByCriterion(a, b, criterion);
          if (cmp != 0) return cmp;
        }
        return 0;
      });
      return sorted;
    }

    final criteria = _sortPreferences.sanitizedCriteria(const [
      SortField.deadlineDate,
      SortField.startDate,
      SortField.createdDate,
      SortField.updatedDate,
      SortField.name,
    ]);
    return compareSorted(projects, criteria);
  }

  Future<void> _onSubscriptionRequested(
    ProjectOverviewSubscriptionRequested event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    emit(const ProjectOverviewLoading());

    // Load initial sort preferences from settings
    if (_settingsRepository != null && _pageKey != null) {
      final savedSort = await _settingsRepository.loadPageSort(_pageKey);
      if (savedSort != null) {
        _sortPreferences = savedSort;
      }
    }

    // Subscribe to task counts if task repository is available
    if (_taskRepository != null) {
      await _taskCountsSubscription?.cancel();
      _taskCountsSubscription = _taskRepository
          .watchTaskCountsByProject()
          .listen((taskCounts) {
            add(ProjectOverviewEvent.taskCountsUpdated(taskCounts: taskCounts));
          });
    }

    await subscribeToStream(
      emit,
      stream: _projectRepository.watchAll(withRelated: _withRelated),
      onData: _sortProjects,
    );
  }

  void _onTaskCountsUpdated(
    ProjectOverviewTaskCountsUpdated event,
    Emitter<ProjectOverviewState> emit,
  ) {
    state.maybeWhen(
      loaded: (projects, _) => emit(
        ProjectOverviewLoaded(projects: projects, taskCounts: event.taskCounts),
      ),
      orElse: () {},
    );
  }

  Future<void> _onToggleCompletion(
    ProjectOverviewToggleProjectCompletion event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    await executeToggle(
      emit,
      toggle: () => _projectRepository.update(
        id: event.project.id,
        name: event.project.name,
        completed: !event.project.completed,
      ),
    );
  }

  void _onSortChanged(
    ProjectOverviewSortChanged event,
    Emitter<ProjectOverviewState> emit,
  ) {
    _sortPreferences = event.preferences;

    // Persist sort preferences (fire and forget)
    if (_settingsRepository != null && _pageKey != null) {
      unawaited(_settingsRepository.savePageSort(_pageKey, event.preferences));
    }

    state.maybeWhen(
      loaded: (projects, taskCounts) => emit(
        ProjectOverviewLoaded(
          projects: _sortProjects(projects),
          taskCounts: taskCounts,
        ),
      ),
      orElse: () {},
    );
  }

  Future<void> _onDisplaySettingsChanged(
    ProjectOverviewDisplaySettingsChanged event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    // Persist display settings
    if (_settingsRepository != null && _pageKey != null) {
      await _settingsRepository.savePageDisplaySettings(
        _pageKey,
        event.settings,
      );
    }
  }

  Future<void> _onDeleteProject(
    ProjectOverviewDeleteProject event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    await executeDelete(
      emit,
      delete: () => _projectRepository.delete(event.project.id),
    );
  }

  @override
  Future<void> close() async {
    await _taskCountsSubscription?.cancel();
    return super.close();
  }
}
