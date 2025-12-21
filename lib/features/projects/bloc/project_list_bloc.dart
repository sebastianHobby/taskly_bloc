import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
part 'project_list_bloc.freezed.dart';

// Define the various events that ProjectsBloc will handle
@freezed
sealed class ProjectOverviewEvent with _$ProjectOverviewEvent {
  const factory ProjectOverviewEvent.projectsSubscriptionRequested() =
      ProjectOverviewSubscriptionRequested;
  const factory ProjectOverviewEvent.toggleProjectCompletion({
    required Project project,
  }) = ProjectOverviewToggleProjectCompletion;
}

// Define the various states that ProjectsBloc can emit
@freezed
sealed class ProjectOverviewState with _$ProjectOverviewState {
  const factory ProjectOverviewState.initial() = ProjectOverviewInitial;
  const factory ProjectOverviewState.loading() = ProjectOverviewLoading;
  const factory ProjectOverviewState.loaded({
    required List<Project> projects,
  }) = ProjectOverviewLoaded;
  const factory ProjectOverviewState.error({required Object error}) =
      ProjectOverviewError;
}

class ProjectOverviewBloc
    extends Bloc<ProjectOverviewEvent, ProjectOverviewState> {
  ProjectOverviewBloc({required ProjectRepositoryContract projectRepository})
    : _projectRepository = projectRepository,
      super(const ProjectOverviewInitial()) {
    on<ProjectOverviewSubscriptionRequested>(onSubscriptionRequested);
    on<ProjectOverviewToggleProjectCompletion>(onProjectToggleCompletion);
  }

  final ProjectRepositoryContract _projectRepository;

  Future<void> onSubscriptionRequested(
    ProjectOverviewSubscriptionRequested event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    // // Send state indicating loading is in progress for UI
    emit(const ProjectOverviewLoading());
    // For each ProjectModel we receive in the stream emit the data loaded
    // state so UI can update or error state if there is an error
    await emit.forEach<List<Project>>(
      _projectRepository.watchAll(),
      onData: (projects) => ProjectOverviewLoaded(projects: projects),
      onError: (error, stackTrace) => ProjectOverviewError(error: error),
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
}
