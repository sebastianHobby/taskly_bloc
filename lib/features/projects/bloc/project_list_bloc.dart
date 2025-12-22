import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
part 'project_list_bloc.freezed.dart';

// Define the various events that ProjectsBloc will handle
@freezed
sealed class ProjectOverviewEvent with _$ProjectOverviewEvent {
  const factory ProjectOverviewEvent.projectsSubscriptionRequested() =
      ProjectOverviewSubscriptionRequested;
  const factory ProjectOverviewEvent.toggleProjectCompletion({
    required Project project,
  }) = ProjectOverviewToggleProjectCompletion;
  const factory ProjectOverviewEvent.sortChanged({
    required SortPreferences preferences,
  }) = ProjectOverviewSortChanged;
  const factory ProjectOverviewEvent.taskCountsUpdated({
    required Map<String, ProjectTaskCounts> taskCounts,
  }) = ProjectOverviewTaskCountsUpdated;
}

// Define the various states that ProjectsBloc can emit
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
    extends Bloc<ProjectOverviewEvent, ProjectOverviewState> {
  ProjectOverviewBloc({
    required ProjectRepositoryContract projectRepository,
    TaskRepositoryContract? taskRepository,
    bool withRelated = false,
    SortPreferences initialSortPreferences = const SortPreferences(),
  }) : _projectRepository = projectRepository,
       _taskRepository = taskRepository,
       _withRelated = withRelated,
       _sortPreferences = initialSortPreferences,
       super(const ProjectOverviewInitial()) {
    on<ProjectOverviewSubscriptionRequested>(onSubscriptionRequested);
    on<ProjectOverviewToggleProjectCompletion>(onProjectToggleCompletion);
    on<ProjectOverviewSortChanged>(onSortChanged);
    on<ProjectOverviewTaskCountsUpdated>(onTaskCountsUpdated);
  }

  final ProjectRepositoryContract _projectRepository;
  final TaskRepositoryContract? _taskRepository;
  final bool _withRelated;
  SortPreferences _sortPreferences;
  StreamSubscription<Map<String, ProjectTaskCounts>>? _taskCountsSubscription;

  SortPreferences get currentSortPreferences => _sortPreferences;

  List<Project> _sortProjects(List<Project> projects) {
    List<Project> compareSorted(List<Project> source, List<SortCriterion> c) {
      int compareByCriterion(Project a, Project b, SortCriterion criterion) {
        final modifier = criterion.direction == SortDirection.ascending
            ? 1
            : -1;
        final value = switch (criterion.field) {
          SortField.name => compareAsciiLowerCase(a.name, b.name),
          SortField.startDate => compareNullableDate(
            a.startDate,
            b.startDate,
          ),
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

    final criteria = _sortPreferences.sanitizedCriteria(
      const [
        SortField.deadlineDate,
        SortField.startDate,
        SortField.createdDate,
        SortField.updatedDate,
        SortField.name,
      ],
    );
    return compareSorted(projects, criteria);
  }

  Future<void> onSubscriptionRequested(
    ProjectOverviewSubscriptionRequested event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    // Send state indicating loading is in progress for UI
    emit(const ProjectOverviewLoading());

    // Subscribe to task counts if task repository is available
    if (_taskRepository != null) {
      await _taskCountsSubscription?.cancel();
      _taskCountsSubscription = _taskRepository
          .watchTaskCountsByProject()
          .listen((taskCounts) {
            add(ProjectOverviewEvent.taskCountsUpdated(taskCounts: taskCounts));
          });
    }

    // For each ProjectModel we receive in the stream emit the data loaded
    // state so UI can update or error state if there is an error
    await emit.forEach<List<Project>>(
      _projectRepository.watchAll(withRelated: _withRelated),
      onData: (projects) {
        final currentCounts = state.maybeWhen(
          loaded: (_, taskCounts) => taskCounts,
          orElse: () => <String, ProjectTaskCounts>{},
        );
        return ProjectOverviewLoaded(
          projects: _sortProjects(projects),
          taskCounts: currentCounts,
        );
      },
      onError: (error, stackTrace) => ProjectOverviewError(error: error),
    );
  }

  void onTaskCountsUpdated(
    ProjectOverviewTaskCountsUpdated event,
    Emitter<ProjectOverviewState> emit,
  ) {
    state.maybeWhen(
      loaded: (projects, _) => emit(
        ProjectOverviewLoaded(
          projects: projects,
          taskCounts: event.taskCounts,
        ),
      ),
      orElse: () {},
    );
  }

  Future<void> onProjectToggleCompletion(
    ProjectOverviewToggleProjectCompletion event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    final project = event.project;

    try {
      await _projectRepository.update(
        id: project.id,
        name: project.name,
        completed: !project.completed,
      );
    } catch (error) {
      emit(ProjectOverviewError(error: error));
    }
  }

  void onSortChanged(
    ProjectOverviewSortChanged event,
    Emitter<ProjectOverviewState> emit,
  ) {
    _sortPreferences = event.preferences;
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

  @override
  Future<void> close() async {
    await _taskCountsSubscription?.cancel();
    return super.close();
  }
}
