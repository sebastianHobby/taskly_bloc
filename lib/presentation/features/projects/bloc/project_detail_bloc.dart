import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/presentation/shared/bloc/detail_bloc_error.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
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
    required AppErrorReporter errorReporter,
  }) : _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _errorReporter = errorReporter,
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
  final AppErrorReporter _errorReporter;
  final ProjectCommandHandler _commandHandler;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? entityId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'projects',
      screen: 'project_detail',
      intent: intent,
      operation: operation,
      entityType: 'project',
      entityId: entityId,
      extraFields: extraFields,
    );
  }

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

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unexpected failure)',
      );
      return;
    }

    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unmapped exception)',
      );
    }
  }

  DetailBlocError<Project> _toUiSafeError(
    Object error,
    StackTrace? stackTrace,
  ) {
    if (error is AppFailure) {
      return DetailBlocError<Project>(
        error: error.uiMessage(),
        stackTrace: stackTrace,
      );
    }

    return DetailBlocError<Project>(error: error, stackTrace: stackTrace);
  }

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
    final context = _newContext(
      intent: 'project_update_requested',
      operation: 'projects.update',
      entityId: event.command.id,
    );
    await _executeValidatedCommand(
      emit,
      EntityOperation.update,
      () => _commandHandler.handleUpdate(event.command, context: context),
      context: context,
    );
  }

  Future<void> _onDelete(
    _ProjectDetailDelete event,
    Emitter<ProjectDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'project_delete_requested',
      operation: 'projects.delete',
      entityId: event.id,
    );

    try {
      await _projectRepository.delete(event.id, context: context);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      emit(createOperationSuccessState(EntityOperation.delete));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Project delete failed',
      );
      emit(createOperationFailureState(_toUiSafeError(error, stackTrace)));
    }
  }

  Future<void> _onCreate(
    _ProjectDetailCreate event,
    Emitter<ProjectDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'project_create_requested',
      operation: 'projects.create',
    );
    await _executeValidatedCommand(
      emit,
      EntityOperation.create,
      () => _commandHandler.handleCreate(event.command, context: context),
      context: context,
    );
  }

  Future<void> _onSetPinned(
    _ProjectDetailSetPinned event,
    Emitter<ProjectDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'project_set_pinned_requested',
      operation: 'projects.setPinned',
      entityId: event.id,
      extraFields: <String, Object?>{'isPinned': event.isPinned},
    );

    try {
      await _projectRepository.setPinned(
        id: event.id,
        isPinned: event.isPinned,
        context: context,
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
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Project setPinned failed',
      );
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: DetailBlocError<Project>(
            error: error is AppFailure ? error.uiMessage() : error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _executeValidatedCommand(
    Emitter<ProjectDetailState> emit,
    EntityOperation operation,
    Future<CommandResult> Function() execute, {
    required OperationContext context,
  }) async {
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
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Project ${operation.name} failed',
      );
      emit(
        createOperationFailureState(
          _toUiSafeError(error, stackTrace),
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
