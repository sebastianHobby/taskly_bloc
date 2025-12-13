part of 'projects_bloc.dart';

@freezed
sealed class ProjectsState with _$ProjectsState {
  const factory ProjectsState.initial() = ProjectsInitial;
  const factory ProjectsState.loading() = ProjectsLoading;
  const factory ProjectsState.loaded({
    required List<ProjectDto> projects,
  }) = ProjectsLoaded;
  const factory ProjectsState.error({required String message}) = ProjectsError;
}
