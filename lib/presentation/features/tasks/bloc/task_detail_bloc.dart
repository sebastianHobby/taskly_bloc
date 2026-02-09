import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/shared/bloc/detail_bloc_error.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/services.dart';

part 'task_detail_bloc.freezed.dart';

// Events
@freezed
sealed class TaskDetailEvent with _$TaskDetailEvent {
  const factory TaskDetailEvent.update({
    required UpdateTaskCommand command,
  }) = _TaskDetailUpdate;

  const factory TaskDetailEvent.create({
    required CreateTaskCommand command,
    @Default(false) bool includeInMyDay,
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
    required TaskWriteService taskWriteService,
    required TaskMyDayWriteService taskMyDayWriteService,
    required AppErrorReporter errorReporter,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
    String? taskId,
    bool autoLoad = true,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _taskWriteService = taskWriteService,
       _taskMyDayWriteService = taskMyDayWriteService,
       _errorReporter = errorReporter,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider,
       super(const TaskDetailState.initial()) {
    on<_TaskDetailLoadInitialData>(
      _onLoadInitialData,
      transformer: restartable(),
    );
    on<_TaskDetailLoadById>(_onGet, transformer: restartable());
    on<_TaskDetailCreate>(_onCreate, transformer: droppable());
    on<_TaskDetailUpdate>(_onUpdate, transformer: droppable());

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
  final TaskWriteService _taskWriteService;
  final TaskMyDayWriteService _taskMyDayWriteService;
  final AppErrorReporter _errorReporter;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;
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
      final useDemo = _demoModeService.isEnabled;
      final projects = useDemo
          ? _demoDataProvider.projects
          : await _projectRepository.getAll();
      final values = useDemo
          ? _demoDataProvider.values
          : await _valueRepository.getAll();

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
        'include_in_my_day': event.includeInMyDay,
      },
    );
    final createAction = event.includeInMyDay
        ? () => _taskMyDayWriteService.createAndPickForToday(
            event.command,
            bucket: MyDayPickBucket.manual,
            context: context,
          )
        : () => _taskWriteService.create(event.command, context: context);
    await _executeValidatedCommand(
      emit,
      EntityOperation.create,
      createAction,
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
      () => _taskWriteService.update(event.command, context: context),
      context: context,
    );
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
