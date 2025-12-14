import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/models/project_models.dart';
part 'project_detail_bloc.freezed.dart';

// Events
@freezed
sealed class ProjectDetailEvent with _$ProjectDetailEvent {
  const factory ProjectDetailEvent.updateProject({
    required ProjectActionRequestUpdate updateRequest,
  }) = _ProjectDetailUpdate;
  const factory ProjectDetailEvent.deleteProject({
    required ProjectActionRequestDelete deleteRequest,
  }) = _ProjectDetailDelete;
  const factory ProjectDetailEvent.createProject({
    required ProjectActionRequestCreate createRequest,
  }) = _ProjectDetailCreate;
}

// State
@freezed
sealed class ProjectDetailState with _$ProjectDetailState {
  const factory ProjectDetailState.initial() = _ProjectDetailInitial;
  const factory ProjectDetailState.error({
    required String message,
    required StackTrace stacktrace,
  }) = _ProjectDetailError;
}

class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState> {
  ProjectDetailBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(const ProjectDetailState.initial()) {
    on<ProjectDetailEvent>((event, emit) async {
      await event.when(
        updateProject: (updateRequest) async => _onUpdate(updateRequest, emit),
        deleteProject: (deleteRequest) async => _onDelete(deleteRequest, emit),
        createProject: (createRequest) async => _onCreate(createRequest, emit),
      );
    });
  }

  final ProjectRepository _projectRepository;

  Future<void> _onUpdate(
    ProjectActionRequestUpdate updateRequest,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.updateProject(updateRequest);
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
    ProjectActionRequestDelete deleteRequest,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.deleteProject(deleteRequest);
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
    ProjectActionRequestCreate createRequest,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.createProject(createRequest);
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
