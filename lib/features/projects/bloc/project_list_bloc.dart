import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
part 'project_list_bloc.freezed.dart';

// Define the various events that ProjectsBloc will handle
@freezed
sealed class ProjectOverviewEvent with _$ProjectOverviewEvent {
  const factory ProjectOverviewEvent.projectsSubscriptionRequested() =
      ProjectOverviewSubscriptionRequested;
  const factory ProjectOverviewEvent.toggleProjectCompletion({
    required ProjectTableData projectData,
  }) = ProjectOverviewToggleProjectCompletion;
}

// Define the various states that ProjectsBloc can emit
@freezed
sealed class ProjectOverviewState with _$ProjectOverviewState {
  const factory ProjectOverviewState.initial() = ProjectOverviewInitial;
  const factory ProjectOverviewState.loading() = ProjectOverviewLoading;
  const factory ProjectOverviewState.loaded({
    required List<ProjectTableData> projects,
  }) = ProjectOverviewLoaded;
  const factory ProjectOverviewState.error({required String message}) =
      ProjectOverviewError;
}

class ProjectOverviewBloc
    extends Bloc<ProjectOverviewEvent, ProjectOverviewState> {
  ProjectOverviewBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(const ProjectOverviewInitial()) {
    on<ProjectOverviewSubscriptionRequested>(onSubscriptionRequested);
    on<ProjectOverviewToggleProjectCompletion>(onProjectToggleCompletion);
  }

  final ProjectRepository _projectRepository;

  Future<void> onSubscriptionRequested(
    ProjectOverviewSubscriptionRequested event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    // // Send state indicating loading is in progress for UI
    emit(const ProjectOverviewLoading());
    // For each ProjectModel we receive in the stream emit the data loaded
    // state so UI can update or error state if there is an error
    await emit.forEach<List<ProjectTableData>>(
      _projectRepository.getProjects,
      onData: (projects) => ProjectOverviewLoaded(projects: projects),
      onError: (error, stackTrace) =>
          const ProjectOverviewError(message: 'todo error handling'),
    );
  }

  Future<void> onProjectToggleCompletion(
    ProjectOverviewToggleProjectCompletion event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    ProjectTableCompanion updateCompanion = event.projectData.toCompanion(true);
    updateCompanion = updateCompanion.copyWith(
      completed: Value(!event.projectData.completed),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _projectRepository.updateProject(updateCompanion);
    } catch (error) {
      emit(ProjectOverviewError(message: error.toString()));
    }
    // No need to call refresh as the stream subscription will handle it
  }
}
