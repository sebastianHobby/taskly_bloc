part of 'projects_bloc.dart';

@freezed
class ProjectsEvent with _$ProjectsEvent {
  const factory ProjectsEvent.projectsSubscriptionRequested() =
      ProjectsSubscriptionRequested;
  const factory ProjectsEvent.updateProject({
    required ProjectModel initialProject,
    required ProjectModel updatedProject,
  }) = ProjectsUpdateProject;
  const factory ProjectsEvent.deleteProject({
    required ProjectModel project,
  }) = ProjectsDeleteProject;
  const factory ProjectsEvent.createProject({
    required ProjectModel project,
  }) = ProjectsCreateProject;
}
