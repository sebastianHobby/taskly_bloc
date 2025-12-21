import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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

@freezed
abstract class TaskDetailError with _$TaskDetailError {
  const factory TaskDetailError({
    required Object error,
    StackTrace? stackTrace,
  }) = _TaskDetailError;
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
    required TaskDetailError errorDetails,
  }) = TaskDetailOperationFailure;

  const factory TaskDetailState.loadInProgress() = TaskDetailLoadInProgress;
  const factory TaskDetailState.loadSuccess({
    required List<Project> availableProjects,
    required List<Label> availableLabels,
    required Task task,
  }) = TaskDetailLoadSuccess;
}

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required LabelRepositoryContract labelRepository,
    String? taskId,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _labelRepository = labelRepository,
       super(const TaskDetailState.initial()) {
    // register handlers for each concrete event type
    on<_TaskDetailLoadInitialData>(_onLoadInitialData);
    on<_TaskDetailGet>(_onGet);
    on<_TaskDetailCreate>(_onCreate);
    on<_TaskDetailUpdate>(_onUpdate);
    on<_TaskDetailDelete>(_onDelete);

    // Only load initial data OR get specific task (not both).
    if (taskId != null && taskId.isNotEmpty) {
      add(TaskDetailEvent.get(taskId: taskId));
    } else {
      add(const TaskDetailEvent.loadInitialData());
    }
  }

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final LabelRepositoryContract _labelRepository;

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
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            error: error,
            stackTrace: stacktrace,
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
      final task = await _taskRepository.get(event.taskId, withRelated: true);
      if (task == null) {
        emit(
          const TaskDetailState.operationFailure(
            errorDetails: TaskDetailError(error: NotFoundEntity.task),
          ),
        );
        return;
      }

      // Use existing repositories to supply available lists for the form
      final projects = await _projectRepository.getAll();
      final labels = await _labelRepository.getAll();

      emit(
        TaskDetailState.loadSuccess(
          task: task,
          availableProjects: projects,
          availableLabels: labels,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate(
    _TaskDetailCreate event,
    Emitter<TaskDetailState> emit,
  ) async {
    try {
      await _taskRepository.create(
        name: event.name,
        description: event.description,
        completed: event.completed,
        startDate: event.startDate,
        deadlineDate: event.deadlineDate,
        projectId: event.projectId,
        repeatIcalRrule: event.repeatIcalRrule,
        labelIds: event.labels?.map((e) => e.id).toList(growable: false),
      );
      emit(
        const TaskDetailState.operationSuccess(
          operation: EntityOperation.create,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    _TaskDetailUpdate event,
    Emitter<TaskDetailState> emit,
  ) async {
    try {
      await _taskRepository.update(
        id: event.id,
        name: event.name,
        description: event.description,
        completed: event.completed,
        projectId: event.projectId,
        startDate: event.startDate,
        deadlineDate: event.deadlineDate,
        repeatIcalRrule: event.repeatIcalRrule,
        labelIds: event.labels?.map((e) => e.id).toList(growable: false),
      );

      emit(
        const TaskDetailState.operationSuccess(
          operation: EntityOperation.update,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete(
    _TaskDetailDelete event,
    Emitter<TaskDetailState> emit,
  ) async {
    try {
      await _taskRepository.delete(event.id);
      emit(
        const TaskDetailState.operationSuccess(
          operation: EntityOperation.delete,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }
}
