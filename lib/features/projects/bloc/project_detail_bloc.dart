import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
part 'project_detail_bloc.freezed.dart';

// Events
@freezed
sealed class ProjectDetailEvent with _$ProjectDetailEvent {
  const factory ProjectDetailEvent.updateProject({
    required ProjectTableCompanion updateCompanion,
  }) = _ProjectDetailUpdate;
  const factory ProjectDetailEvent.deleteProject({
    required ProjectTableCompanion deleteCompanion,
  }) = _ProjectDetailDelete;
  const factory ProjectDetailEvent.createProject({
    required ProjectTableCompanion createCompanion,
  }) = _ProjectDetailCreate;
  const factory ProjectDetailEvent.getProject({required String projectId}) =
      _ProjectDetailGet;
}

// State
@freezed
sealed class ProjectDetailState with _$ProjectDetailState {
  const factory ProjectDetailState.loading() = _ProjectDetailLoading;
  const factory ProjectDetailState.createProject() = _ProjectDetailNewProject;
  const factory ProjectDetailState.editProject() = _ProjectDetailEditProject;
  const factory ProjectDetailState.error({
    required String message,
    required StackTrace stacktrace,
  }) = _ProjectDetailError;
}

class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState> {
  ProjectDetailBloc({
    required ProjectRepository projectRepository,
    String? projectId,
  }) : _projectRepository = projectRepository,
       super(const ProjectDetailState.loading()) {
    on<ProjectDetailEvent>((event, emit) async {
      await event.when(
        getProject: (projectId) async => _onGet(projectId, emit),
        updateProject: (updateRequest) async => _onUpdate(updateRequest, emit),
        deleteProject: (deleteRequest) async => _onDelete(deleteRequest, emit),
        createProject: (createRequest) async => _onCreate(createRequest, emit),
      );
      // If no projectId, show create project. Otherwise request the project.
      if (projectId == null) {
        emit(const ProjectDetailState.createProject());
      } else {
        add(ProjectDetailEvent.getProject(projectId: projectId));
      }
    });
  }
  final ProjectRepository _projectRepository;

  Future _onGet(
    String projectId,
    Emitter<ProjectDetailState> emit,
  ) async {
    emit(const ProjectDetailState.loading());
    try {
      final project = await _projectRepository.getProjectById(projectId);
      if (project == null) {
        emit(const ProjectDetailState.createProject());
      } else {
        emit(const ProjectDetailState.editProject());
      }
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }

  Future<void> _onUpdate(
    ProjectTableCompanion updateCompanion,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.updateProject(updateCompanion);
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }

  Future<void> _onDelete(
    ProjectTableCompanion deleteCompanion,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.deleteProject(deleteCompanion);
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }

  Future<void> _onCreate(
    ProjectTableCompanion createCompanion,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.createProject(createCompanion);
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }
}
