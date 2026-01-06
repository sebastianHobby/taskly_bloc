import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';

part 'task_detail_bloc.freezed.dart';

// Events
@freezed
sealed class TaskDetailEvent with _$TaskDetailEvent {
  const factory TaskDetailEvent.update({
    required String id,
    required String name,
    required String? description,
    required bool completed,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    List<String>? valueIds,
  }) = _TaskDetailUpdate;
  const factory TaskDetailEvent.delete({
    required String id,
  }) = _TaskDetailDelete;

  const factory TaskDetailEvent.create({
    required String name,
    required String? description,
    @Default(false) bool completed,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    List<String>? valueIds,
  }) = _TaskDetailCreate;

  const factory TaskDetailEvent.loadById({required String taskId}) =
      _TaskDetailLoadById;
  const factory TaskDetailEvent.loadInitialData() = _TaskDetailLoadInitialData;
}

// State
@freezed
class TaskDetailState with _$TaskDetailState {
  const factory TaskDetailState.initial() = TaskDetailInitial;

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
    String? taskId,
    bool autoLoad = true,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       super(const TaskDetailState.initial()) {
    on<_TaskDetailLoadInitialData>(_onLoadInitialData);
    on<_TaskDetailLoadById>(_onGet);
    on<_TaskDetailCreate>(_onCreate);
    on<_TaskDetailUpdate>(_onUpdate);
    on<_TaskDetailDelete>(_onDelete);

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

  @override
  Talker get logger => talker;

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
    await executeCreateOperation(
      emit,
      () => _taskRepository.create(
        name: event.name,
        description: event.description,
        completed: event.completed,
        startDate: event.startDate,
        deadlineDate: event.deadlineDate,
        projectId: event.projectId,
        priority: event.priority,
        repeatIcalRrule: event.repeatIcalRrule,
        valueIds: event.valueIds,
      ),
    );
  }

  Future<void> _onUpdate(
    _TaskDetailUpdate event,
    Emitter<TaskDetailState> emit,
  ) async {
    await executeUpdateOperation(
      emit,
      () async {
        await _taskRepository.update(
          id: event.id,
          name: event.name,
          description: event.description,
          completed: event.completed,
          projectId: event.projectId,
          priority: event.priority,
          startDate: event.startDate,
          deadlineDate: event.deadlineDate,
          repeatIcalRrule: event.repeatIcalRrule,
          valueIds: event.valueIds,
        );
      },
    );
  }

  Future<void> _onDelete(
    _TaskDetailDelete event,
    Emitter<TaskDetailState> emit,
  ) async {
    await executeDeleteOperation(emit, () => _taskRepository.delete(event.id));
  }
}
