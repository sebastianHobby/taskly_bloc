import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/dtos/projects/project_dto.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/models/project_models.dart';
part 'project_list_bloc.freezed.dart';

// Define the various events that ProjectsBloc will handle
@freezed
sealed class ProjectListEvent with _$ProjectListEvent {
  const factory ProjectListEvent.projectsSubscriptionRequested() =
      ProjectListSubscriptionRequested;
  const factory ProjectListEvent.toggleProjectCompletion({required ProjectDto projectDto}) = ProjectListToggleProjectCompletion;
}

// Define the various states that ProjectsBloc can emit
@freezed
sealed class ProjectListState with _$ProjectListState {
  const factory ProjectListState.initial() = ProjectListInitial;
  const factory ProjectListState.loading() = ProjectListLoading;
  const factory ProjectListState.loaded({
    required List<ProjectDto> projects,
  }) = ProjectListLoaded;
  const factory ProjectListState.error({required String message}) =
      ProjectListError;
}

class ProjectListBloc extends Bloc<ProjectListEvent, ProjectListState> {
  ProjectListBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(const ProjectListInitial()) {
    on<ProjectListSubscriptionRequested>(onSubscriptionRequested);
    on<ProjectListToggleProjectCompletion>(onProjectToggleCompletion);
  }

  final ProjectRepository _projectRepository;

  Future<void> onSubscriptionRequested(
    ProjectListSubscriptionRequested event,
    Emitter<ProjectListState> emit,
  ) async {
    // // Send state indicating loading is in progress for UI
    emit(const ProjectListLoading());
    // For each ProjectModel we receive in the stream emit the data loaded
    // state so UI can update or error state if there is an error
    await emit.forEach<List<ProjectDto>>(
      _projectRepository.getProjects(),
      onData: (projects) => ProjectListLoaded(projects: projects),
      onError: (error, stackTrace) =>
          const ProjectListError(message: 'todo error handling'),
    );
  }

  Future<void> onProjectToggleCompletion(
    ProjectListToggleProjectCompletion event,
    Emitter<ProjectListState> emit,
  ) async {
    final updatedProject = event.projectDto.copyWith(
      completed: !event.projectDto.completed,
    );
    final updateRequest = ProjectActionRequestUpdate(
      name: updatedProject.name,
      completed: updatedProject.completed,
      description: updatedProject.description, projectToUpdate: updatedProject,
    );
    await _projectRepository.updateProject(updateRequest);
    // No need to call refresh as the stream subscription will handle it
  }


}
