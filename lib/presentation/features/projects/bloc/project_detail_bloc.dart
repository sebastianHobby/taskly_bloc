import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';

part 'project_detail_bloc.freezed.dart';

// Events
@freezed
sealed class ProjectDetailEvent with _$ProjectDetailEvent {
  const factory ProjectDetailEvent.update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    int? priority,
    String? repeatIcalRrule,
    List<String>? valueIds,
  }) = _ProjectDetailUpdate;
  const factory ProjectDetailEvent.delete({
    required String id,
  }) = _ProjectDetailDelete;

  const factory ProjectDetailEvent.create({
    required String name,
    String? description,
    @Default(false) bool completed,
    DateTime? startDate,
    DateTime? deadlineDate,
    int? priority,
    String? repeatIcalRrule,
    List<String>? valueIds,
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
       super(const ProjectDetailState.initial()) {
    on<_ProjectDetailLoadById>((event, emit) => _onGet(event.projectId, emit));
    on<_ProjectDetailCreate>(_onCreate);
    on<_ProjectDetailUpdate>(_onUpdate);
    on<_ProjectDetailDelete>(_onDelete);
    on<_ProjectDetailLoadInitialData>(
      (event, emit) => _onLoadInitialData(emit),
    );
  }

  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;

  @override
  Talker get logger => talker;

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
    await executeUpdateOperation(
      emit,
      () => _projectRepository.update(
        id: event.id,
        name: event.name,
        description: event.description,
        completed: event.completed,
        startDate: event.startDate,
        deadlineDate: event.deadlineDate,
        valueIds: event.valueIds,
      ),
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
    await executeCreateOperation(
      emit,
      () => _projectRepository.create(
        name: event.name,
        description: event.description,
        completed: event.completed,
        startDate: event.startDate,
        deadlineDate: event.deadlineDate,
        priority: event.priority,
        repeatIcalRrule: event.repeatIcalRrule,
        valueIds: event.valueIds,
      ),
    );
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
