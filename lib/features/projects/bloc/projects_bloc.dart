import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/dtos/projects/project_dto.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/models/project_models.dart';

part 'projects_event.dart';
part 'projects_state.dart';
part 'projects_bloc.freezed.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  ProjectsBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(const ProjectsInitial()) {
    on<ProjectsSubscriptionRequested>(onSubscriptionRequested);
    on<ProjectsUpdateProject>(onProjectUpdate);
    on<ProjectsDeleteProject>(onProjectDelete);
    on<ProjectsCreateProject>(onProjectCreate);
  }

  final ProjectRepository _projectRepository;

  Future<void> onSubscriptionRequested(
    ProjectsSubscriptionRequested event,
    Emitter<ProjectsState> emit,
  ) async {
    // // Send state indicating loading is in progress for UI
    emit(const ProjectsLoading());

    // For each ProjectModel we receive in the stream emit the data loaded
    // state so UI can update or error state if there is an error
    await emit.forEach<List<ProjectDto>>(
      _projectRepository.getProjects(),
      onData: (projects) => ProjectsLoaded(projects: projects),
      onError: (error, stackTrace) =>
          const ProjectsError(message: 'todo error handling'),
    );
  }

  Future<void> onProjectUpdate(
    ProjectsUpdateProject event,
    Emitter<ProjectsState> emit,
  ) async {
    _projectRepository.updateProject(event.updateRequest);
    // No need to call refresh as the stream subscription will handle it
  }

  Future<void> onProjectDelete(
    ProjectsDeleteProject event,
    Emitter<ProjectsState> emit,
  ) async {
    _projectRepository.deleteProject(event.deleteRequest);
    // No need to call refresh as the stream subscription will handle it
  }

  Future<void> onProjectCreate(
    ProjectsCreateProject event,
    Emitter<ProjectsState> emit,
  ) async {
    _projectRepository.createProject(event.createRequest);
    // No need to call refresh as the stream subscription will handle it
  }
}
