import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';

part 'project_detail_bloc.freezed.dart';

// Events
@freezed
sealed class ProjectDetailEvent with _$ProjectDetailEvent {
  const factory ProjectDetailEvent.update({
    required String id,
    required String name,
    required String description,
    required bool completed,
  }) = _ProjectDetailUpdate;
  const factory ProjectDetailEvent.delete({
    required String id,
  }) = _ProjectDetailDelete;

  const factory ProjectDetailEvent.create({
    required String name,
    required String description,
  }) = _ProjectDetailCreate;

  const factory ProjectDetailEvent.get({required String projectId}) =
      _ProjectDetailGet;
}

@freezed
abstract class ProjectDetailError with _$ProjectDetailError {
  const factory ProjectDetailError({
    required String message,
    StackTrace? stackTrace,
  }) = _ProjectDetailError;
}

// State
@freezed
class ProjectDetailState with _$ProjectDetailState {
  const factory ProjectDetailState.initial() = ProjectDetailInitial;

  // Returns success or failure after create, update, delete operations
  const factory ProjectDetailState.operationSuccess({required String message}) =
      ProjectDetailOperationSuccess;
  const factory ProjectDetailState.operationFailure({
    required ProjectDetailError errorDetails,
  }) = ProjectDetailOperationFailure;

  // States for loading a project
  const factory ProjectDetailState.loadInProgress() =
      ProjectDetailLoadInProgress;
  const factory ProjectDetailState.loadSuccess({
    required ProjectTableData project,
  }) = ProjectDetailLoadSuccess;
}

class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState> {
  ProjectDetailBloc({
    required ProjectRepository projectRepository,
    String? projectId,
  }) : _projectRepository = projectRepository,
       super(const ProjectDetailState.initial()) {
    on<ProjectDetailEvent>((event, emit) async {
      await event.when(
        get: (projectId) async => _onGet(projectId, emit),
        update: (id, name, description, completed) async =>
            _onUpdate(id, name, description, completed, emit),
        delete: (id) async => _onDelete(id, emit),
        create: (name, description) async => _onCreate(name, description, emit),
      );
    });
    if (projectId != null) {
      add(ProjectDetailEvent.get(projectId: projectId));
    }
  }
  final ProjectRepository _projectRepository;

  Future _onGet(
    String projectId,
    Emitter<ProjectDetailState> emit,
  ) async {
    emit(const ProjectDetailState.loadInProgress());
    try {
      final project = await _projectRepository.getProjectById(projectId);
      if (project == null) {
        emit(
          const ProjectDetailState.operationFailure(
            errorDetails: ProjectDetailError(message: 'Project not found'),
          ),
        );
      } else {
        emit(ProjectDetailState.loadSuccess(project: project));
      }
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    String id,
    String name,
    String description,
    bool completed,
    Emitter<ProjectDetailState> emit,
  ) async {
    final updateCompanion = ProjectTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _projectRepository.updateProject(updateCompanion);
      emit(
        ProjectDetailState.operationSuccess(
          message: 'Project updated successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete(
    String id,
    Emitter<ProjectDetailState> emit,
  ) async {
    final deleteCompanion = ProjectTableCompanion(
      id: Value(id),
    );
    try {
      await _projectRepository.deleteProject(deleteCompanion);
      emit(
        const ProjectDetailState.operationSuccess(
          message: 'Project deleted successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate(
    String name,
    String description,
    Emitter<ProjectDetailState> emit,
  ) async {
    final createCompanion = ProjectTableCompanion(
      name: Value(name),
      description: Value(description),
      completed: Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _projectRepository.createProject(createCompanion);
      emit(
        const ProjectDetailState.operationSuccess(
          message: 'Project created successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }
}
