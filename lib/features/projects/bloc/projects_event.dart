part of 'projects_bloc.dart';

@freezed
class ProjectsEvent with _$ProjectsEvent {
  const factory ProjectsEvent.projectsSubscriptionRequested() =
      ProjectsSubscriptionRequested;
  const factory ProjectsEvent.updateProject({
    required ProjectUpdateRequest updateRequest,
  }) = ProjectsUpdateProject;
  const factory ProjectsEvent.deleteProject({
    required ProjectDeleteRequest deleteRequest,
  }) = ProjectsDeleteProject;
  const factory ProjectsEvent.createProject({
    required ProjectCreateRequest createRequest,
  }) = ProjectsCreateProject;
}
