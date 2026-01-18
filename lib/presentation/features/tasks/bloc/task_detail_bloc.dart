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

part 'task_detail_bloc.freezed.dart';

// Events
@freezed
sealed class TaskDetailEvent with _$TaskDetailEvent {
  const factory TaskDetailEvent.update({
    required UpdateTaskCommand command,
  }) = _TaskDetailUpdate;
  const factory TaskDetailEvent.setPinned({
    required String id,
    required bool isPinned,
  }) = _TaskDetailSetPinned;
  const factory TaskDetailEvent.delete({
    required String id,
  }) = _TaskDetailDelete;

  const factory TaskDetailEvent.create({
    required CreateTaskCommand command,
  }) = _TaskDetailCreate;

  const factory TaskDetailEvent.loadById({required String taskId}) =
      _TaskDetailLoadById;
  const factory TaskDetailEvent.loadInitialData() = _TaskDetailLoadInitialData;
}

// State
@freezed
class TaskDetailState with _$TaskDetailState {
  const factory TaskDetailState.initial() = TaskDetailInitial;

  const factory TaskDetailState.inlineActionSuccess({
    required String message,
  }) = TaskDetailInlineActionSuccess;

  const factory TaskDetailState.validationFailure({
    required ValidationFailure failure,
  }) = TaskDetailValidationFailure;

  const factory TaskDetailState.initialDataLoadSuccess({
    required List<Project> availableProjects,
    required List<Value> availableValues,
  }) = TaskDetailInitialDataLoadSuccess;

  const factory TaskDetailState.operationSuccess({
    required EntityOperation operation,
  }) = TaskDetailOperationSuccess;
  const factory TaskDetailState.operationFailure({
    required DetailBlocError<Task> errorDetails,
  }) = TaskDetailOperationFailure;

  const factory TaskDetailState.loadInProgress() = TaskDetailLoadInProgress;
  const factory TaskDetailState.loadSuccess({
    required List<Project> availableProjects,
    required List<Value> availableValues,
    required Task task,
  }) = TaskDetailLoadSuccess;
}

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState>
    with DetailBlocMixin<TaskDetailEvent, TaskDetailState, Task> {
  TaskDetailBloc({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    required AppErrorReporter errorReporter,
    String? taskId,
    bool autoLoad = true,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _errorReporter = errorReporter,
       _commandHandler = TaskCommandHandler(taskRepository: taskRepository),
       super(const TaskDetailState.initial()) {
    on<_TaskDetailLoadInitialData>(
      _onLoadInitialData,
      transformer: restartable(),
    );
    on<_TaskDetailLoadById>(_onGet, transformer: restartable());
    on<_TaskDetailCreate>(_onCreate, transformer: droppable());
    on<_TaskDetailUpdate>(_onUpdate, transformer: droppable());
    on<_TaskDetailSetPinned>(_onSetPinned, transformer: droppable());
    on<_TaskDetailDelete>(_onDelete, transformer: droppable());

    if (autoLoad) {
      if (taskId != null && taskId.isNotEmpty) {
        add(TaskDetailEvent.loadById(taskId: taskId));
      } else {
        add(const TaskDetailEvent.loadInitialData());
      }
    }
  }

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final AppErrorReporter _errorReporter;
  final TaskCommandHandler _commandHandler;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? entityId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'tasks',
      screen: 'task_detail',
      intent: intent,
      operation: operation,
      entityType: 'task',
      entityId: entityId,
      extraFields: extraFields,
    );
  }

  @override
  Talker get logger => talkerRaw;

  // DetailBlocMixin implementation
  @override
  TaskDetailState createLoadInProgressState() =>
      const TaskDetailState.loadInProgress();

  @override
  TaskDetailState createOperationSuccessState(EntityOperation operation) =>
      TaskDetailState.operationSuccess(operation: operation);

  @override
  TaskDetailState createOperationFailureState(DetailBlocError<Task> error) =>
      TaskDetailState.operationFailure(errorDetails: error);

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

  DetailBlocError<Task> _toUiSafeError(Object error, StackTrace? stackTrace) {
    if (error is AppFailure) {
      return DetailBlocError<Task>(
        error: error.uiMessage(),
        stackTrace: stackTrace,
      );
    }

    return DetailBlocError<Task>(error: error, stackTrace: stackTrace);
  }

  Future<void> _onLoadInitialData(
    _TaskDetailLoadInitialData event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(const TaskDetailState.loadInProgress());
    try {
      final projects = await _projectRepository.getAll();
      final values = await _valueRepository.getAll();

      emit(
        TaskDetailState.initialDataLoadSuccess(
          availableProjects: projects,
          availableValues: values,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: DetailBlocError<Task>(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _onGet(
    _TaskDetailLoadById event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(const TaskDetailState.loadInProgress());
    try {
      final task = await _taskRepository.getById(event.taskId);
      if (task == null) {
        emit(
          const TaskDetailState.operationFailure(
            errorDetails: DetailBlocError<Task>(error: NotFoundEntity.task),
          ),
        );
        return;
      }

      final projects = await _projectRepository.getAll();
      final values = await _valueRepository.getAll();

      emit(
        TaskDetailState.loadSuccess(
          task: task,
          availableProjects: projects,
          availableValues: values,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: DetailBlocError<Task>(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate(
    _TaskDetailCreate event,
    Emitter<TaskDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'task_create_requested',
      operation: 'tasks.create',
      extraFields: <String, Object?>{
        'hasProjectId': event.command.projectId != null,
      },
    );
    await _executeValidatedCommand(
      emit,
      EntityOperation.create,
      () => _commandHandler.handleCreate(event.command, context: context),
      context: context,
    );
  }

  Future<void> _onUpdate(
    _TaskDetailUpdate event,
    Emitter<TaskDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'task_update_requested',
      operation: 'tasks.update',
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
    _TaskDetailDelete event,
    Emitter<TaskDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'task_delete_requested',
      operation: 'tasks.delete',
      entityId: event.id,
    );

    try {
      await _taskRepository.delete(event.id, context: context);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      emit(createOperationSuccessState(EntityOperation.delete));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Task delete failed',
      );
      emit(createOperationFailureState(_toUiSafeError(error, stackTrace)));
    }
  }

  Future<void> _onSetPinned(
    _TaskDetailSetPinned event,
    Emitter<TaskDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'task_set_pinned_requested',
      operation: 'tasks.setPinned',
      entityId: event.id,
      extraFields: <String, Object?>{'isPinned': event.isPinned},
    );

    try {
      await _taskRepository.setPinned(
        id: event.id,
        isPinned: event.isPinned,
        context: context,
      );

      emit(
        TaskDetailState.inlineActionSuccess(
          message: event.isPinned ? 'Pinned' : 'Unpinned',
        ),
      );

      // Refresh entity (keep editor open)
      final task = await _taskRepository.getById(event.id);
      if (task == null) {
        emit(
          const TaskDetailState.operationFailure(
            errorDetails: DetailBlocError<Task>(error: NotFoundEntity.task),
          ),
        );
        return;
      }

      final projects = await _projectRepository.getAll();
      final values = await _valueRepository.getAll();
      emit(
        TaskDetailState.loadSuccess(
          task: task,
          availableProjects: projects,
          availableValues: values,
        ),
      );
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Task setPinned failed',
      );
      emit(
        TaskDetailState.operationFailure(
          errorDetails: DetailBlocError<Task>(
            error: error is AppFailure ? error.uiMessage() : error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _executeValidatedCommand(
    Emitter<TaskDetailState> emit,
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
          emit(TaskDetailState.validationFailure(failure: failure));
      }
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Task ${operation.name} failed',
      );
      emit(
        createOperationFailureState(
          _toUiSafeError(error, stackTrace),
        ),
      );
    }
  }
}
