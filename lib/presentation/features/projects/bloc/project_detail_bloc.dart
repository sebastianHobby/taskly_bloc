import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/presentation/shared/bloc/detail_bloc_error.dart';
import 'package:taskly_domain/taskly_domain.dart';

part 'project_detail_bloc.freezed.dart';

// Events
@freezed
sealed class ProjectDetailEvent with _$ProjectDetailEvent {
  const factory ProjectDetailEvent.update({
    required UpdateProjectCommand command,
  }) = _ProjectDetailUpdate;
  const factory ProjectDetailEvent.setPinned({
    required String id,
    required bool isPinned,
  }) = _ProjectDetailSetPinned;
  const factory ProjectDetailEvent.delete({
    required String id,
  }) = _ProjectDetailDelete;

  const factory ProjectDetailEvent.create({
    required CreateProjectCommand command,
  }) = _ProjectDetailCreate;

  const factory ProjectDetailEvent.loadById({required String projectId}) =
      _ProjectDetailLoadById;

  const factory ProjectDetailEvent.loadInitialData() =
      _ProjectDetailLoadInitialData;
}

// State
@freezed
class ProjectDetailState with _$ProjectDetailState {
  const factory ProjectDetailState.initial() = ProjectDetailInitial;

  const factory ProjectDetailState.inlineActionSuccess({
    required String message,
  }) = ProjectDetailInlineActionSuccess;

  const factory ProjectDetailState.validationFailure({
    required ValidationFailure failure,
  }) = ProjectDetailValidationFailure;

  const factory ProjectDetailState.initialDataLoadSuccess({
    required List<Value> availableValues,
  }) = ProjectDetailInitialDataLoadSuccess;

  const factory ProjectDetailState.operationSuccess({
    required EntityOperation operation,
  }) = ProjectDetailOperationSuccess;
  const factory ProjectDetailState.operationFailure({
    required DetailBlocError<Project> errorDetails,
  }) = ProjectDetailOperationFailure;

  const factory ProjectDetailState.loadInProgress() =
      ProjectDetailLoadInProgress;
  const factory ProjectDetailState.loadSuccess({
    required List<Value> availableValues,
    required Project project,
  }) = ProjectDetailLoadSuccess;
}

class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState>
    with DetailBlocMixin<ProjectDetailEvent, ProjectDetailState, Project> {
  ProjectDetailBloc({
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
  }) : _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _commandHandler = ProjectCommandHandler(
         projectRepository: projectRepository,
       ),
       super(const ProjectDetailState.initial()) {
    on<_ProjectDetailLoadById>(
      (event, emit) => _onGet(event.projectId, emit),
      transformer: restartable(),
    );
    on<_ProjectDetailCreate>(_onCreate, transformer: droppable());
    on<_ProjectDetailUpdate>(_onUpdate, transformer: droppable());
    on<_ProjectDetailSetPinned>(_onSetPinned, transformer: droppable());
    on<_ProjectDetailDelete>(_onDelete, transformer: droppable());
    on<_ProjectDetailLoadInitialData>(
      (event, emit) => _onLoadInitialData(emit),
      transformer: restartable(),
    );
  }

  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final ProjectCommandHandler _commandHandler;

  @override
  Talker get logger => talkerRaw;

  @override
  Future<void> close() {
    // Defensive cleanup for page-scoped blocs
    return super.close();
  }

  // DetailBlocMixin implementation
  @override
  ProjectDetailState createLoadInProgressState() =>
      const ProjectDetailState.loadInProgress();

  @override
  ProjectDetailState createOperationSuccessState(EntityOperation operation) =>
      ProjectDetailState.operationSuccess(operation: operation);

  @override
  ProjectDetailState createOperationFailureState(
    DetailBlocError<Project> error,
  ) => ProjectDetailState.operationFailure(errorDetails: error);

  Future<void> _onGet(
    String projectId,
    Emitter<ProjectDetailState> emit,
  ) async {
    emit(const ProjectDetailState.loadInProgress());
    try {
      final values = await _valueRepository.getAll();
      final project = await _projectRepository.getById(projectId);

      if (project == null) {
        emit(
          const ProjectDetailState.operationFailure(
            errorDetails: DetailBlocError<Project>(
              error: NotFoundEntity.project,
            ),
          ),
        );
      } else {
        emit(
          ProjectDetailState.loadSuccess(
            availableValues: values,
            project: project,
          ),
        );
      }
    } catch (error, stackTrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: DetailBlocError<Project>(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    _ProjectDetailUpdate event,
    Emitter<ProjectDetailState> emit,
  ) async {
    await _executeValidatedCommand(
      emit,
      EntityOperation.update,
      () => _commandHandler.handleUpdate(event.command),
    );
  }

  Future<void> _onDelete(
    _ProjectDetailDelete event,
    Emitter<ProjectDetailState> emit,
  ) async {
    await executeDeleteOperation(
      emit,
      () => _projectRepository.delete(event.id),
    );
  }

  Future<void> _onCreate(
    _ProjectDetailCreate event,
    Emitter<ProjectDetailState> emit,
  ) async {
    await _executeValidatedCommand(
      emit,
      EntityOperation.create,
      () => _commandHandler.handleCreate(event.command),
    );
  }

  Future<void> _onSetPinned(
    _ProjectDetailSetPinned event,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.setPinned(
        id: event.id,
        isPinned: event.isPinned,
      );

      emit(
        ProjectDetailState.inlineActionSuccess(
          message: event.isPinned ? 'Pinned' : 'Unpinned',
        ),
      );

      // Refresh entity (keep editor open)
      final values = await _valueRepository.getAll();
      final project = await _projectRepository.getById(event.id);
      if (project == null) {
        emit(
          const ProjectDetailState.operationFailure(
            errorDetails: DetailBlocError<Project>(
              error: NotFoundEntity.project,
            ),
          ),
        );
        return;
      }

      emit(
        ProjectDetailState.loadSuccess(
          availableValues: values,
          project: project,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: DetailBlocError<Project>(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _executeValidatedCommand(
    Emitter<ProjectDetailState> emit,
    EntityOperation operation,
    Future<CommandResult> Function() execute,
  ) async {
    try {
      final result = await execute();
      switch (result) {
        case CommandSuccess():
          await Future<void>.delayed(const Duration(milliseconds: 50));
          emit(createOperationSuccessState(operation));
        case CommandValidationFailure(:final failure):
          emit(ProjectDetailState.validationFailure(failure: failure));
      }
    } catch (error, stackTrace) {
      emit(
        createOperationFailureState(
          DetailBlocError<Project>(error: error, stackTrace: stackTrace),
        ),
      );
    }
  }

  Future<void> _onLoadInitialData(Emitter<ProjectDetailState> emit) async {
    emit(const ProjectDetailState.loadInProgress());
    try {
      final values = await _valueRepository.getAll();
      emit(ProjectDetailState.initialDataLoadSuccess(availableValues: values));
    } catch (error, stackTrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: DetailBlocError<Project>(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }
}
