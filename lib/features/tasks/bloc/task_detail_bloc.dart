import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

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
    String? repeatIcalRrule,
    List<Label>? labels,
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
    String? repeatIcalRrule,
    List<Label>? labels,
  }) = _TaskDetailCreate;

  const factory TaskDetailEvent.get({required String taskId}) = _TaskDetailGet;
  const factory TaskDetailEvent.loadInitialData() = _TaskDetailLoadInitialData;
}

// State
@freezed
class TaskDetailState with _$TaskDetailState {
  const factory TaskDetailState.initial() = TaskDetailInitial;

  const factory TaskDetailState.initialDataLoadSuccess({
    required List<Project> availableProjects,
    required List<Label> availableLabels,
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
    required List<Label> availableLabels,
    required Task task,
  }) = TaskDetailLoadSuccess;
}

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState>
    with DetailBlocMixin<TaskDetailEvent, TaskDetailState, Task> {
  TaskDetailBloc({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required LabelRepositoryContract labelRepository,
    String? taskId,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _labelRepository = labelRepository,
       super(const TaskDetailState.initial()) {
    on<_TaskDetailLoadInitialData>(_onLoadInitialData);
    on<_TaskDetailGet>(_onGet);
    on<_TaskDetailCreate>(_onCreate);
    on<_TaskDetailUpdate>(_onUpdate);
    on<_TaskDetailDelete>(_onDelete);

    if (taskId != null && taskId.isNotEmpty) {
      add(TaskDetailEvent.get(taskId: taskId));
    } else {
      add(const TaskDetailEvent.loadInitialData());
    }
  }

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final LabelRepositoryContract _labelRepository;

  @override
  final logger = AppLogger.forBloc('TaskDetail');

  @override
  Future<void> close() {
    // Defensive cleanup for modal-scoped blocs
    // Ensures resources are released even if modal disposal is irregular
    return super.close();
  }

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
      final labels = await _labelRepository.getAll();

      emit(
        TaskDetailState.initialDataLoadSuccess(
          availableProjects: projects,
          availableLabels: labels,
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
    _TaskDetailGet event,
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
      final labels = await _labelRepository.getAll();

      emit(
        TaskDetailState.loadSuccess(
          task: task,
          availableProjects: projects,
          availableLabels: labels,
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
        repeatIcalRrule: event.repeatIcalRrule,
        labelIds: event.labels?.map((e) => e.id).toList(growable: false),
      ),
    );
  }

  Future<void> _onUpdate(
    _TaskDetailUpdate event,
    Emitter<TaskDetailState> emit,
  ) async {
    await executeUpdateOperation(
      emit,
      () => _taskRepository.update(
        id: event.id,
        name: event.name,
        description: event.description,
        completed: event.completed,
        projectId: event.projectId,
        startDate: event.startDate,
        deadlineDate: event.deadlineDate,
        repeatIcalRrule: event.repeatIcalRrule,
        labelIds: event.labels?.map((e) => e.id).toList(growable: false),
      ),
    );
  }

  Future<void> _onDelete(
    _TaskDetailDelete event,
    Emitter<TaskDetailState> emit,
  ) async {
    await executeDeleteOperation(emit, () => _taskRepository.delete(event.id));
  }
}
