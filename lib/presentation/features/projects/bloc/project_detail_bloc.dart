import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
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
    String? repeatIcalRrule,
    List<Label>? labels,
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
    String? repeatIcalRrule,
    List<Label>? labels,
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
    required List<Label> availableLabels,
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
    required List<Label> availableLabels,
    required Project project,
  }) = ProjectDetailLoadSuccess;
}

class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState>
    with DetailBlocMixin<ProjectDetailEvent, ProjectDetailState, Project> {
  ProjectDetailBloc({
    required ProjectRepositoryContract projectRepository,
    required LabelRepositoryContract labelRepository,
  }) : _projectRepository = projectRepository,
       _labelRepository = labelRepository,
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
  final LabelRepositoryContract _labelRepository;

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
      final labels = await _labelRepository.getAll();
      final project = await _projectRepository.getById(
        projectId,
        withRelated: true,
      );

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
            availableLabels: labels,
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
        repeatIcalRrule: event.repeatIcalRrule,
        labelIds: event.labels?.map((e) => e.id).toList(growable: false),
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
        repeatIcalRrule: event.repeatIcalRrule,
        labelIds: event.labels?.map((e) => e.id).toList(growable: false),
      ),
    );
  }

  Future<void> _onLoadInitialData(Emitter<ProjectDetailState> emit) async {
    emit(const ProjectDetailState.loadInProgress());
    try {
      final labels = await _labelRepository.getAll();
      emit(ProjectDetailState.initialDataLoadSuccess(availableLabels: labels));
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
