import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
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
    List<ValueModel>? values,
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
    List<ValueModel>? values,
    List<Label>? labels,
  }) = _ProjectDetailCreate;

  const factory ProjectDetailEvent.get({required String projectId}) =
      _ProjectDetailGet;

  const factory ProjectDetailEvent.loadInitialData() =
      _ProjectDetailLoadInitialData;
}

@freezed
abstract class ProjectDetailError with _$ProjectDetailError {
  const factory ProjectDetailError({
    required Object error,
    StackTrace? stackTrace,
  }) = _ProjectDetailError;
}

// State
@freezed
class ProjectDetailState with _$ProjectDetailState {
  const factory ProjectDetailState.initial() = ProjectDetailInitial;

  const factory ProjectDetailState.initialDataLoadSuccess({
    required List<ValueModel> availableValues,
    required List<Label> availableLabels,
  }) = ProjectDetailInitialDataLoadSuccess;

  // Returns success or failure after create, update, delete operations
  const factory ProjectDetailState.operationSuccess({
    required EntityOperation operation,
  }) = ProjectDetailOperationSuccess;
  const factory ProjectDetailState.operationFailure({
    required ProjectDetailError errorDetails,
  }) = ProjectDetailOperationFailure;

  // States for loading a project
  const factory ProjectDetailState.loadInProgress() =
      ProjectDetailLoadInProgress;
  const factory ProjectDetailState.loadSuccess({
    required List<ValueModel> availableValues,
    required List<Label> availableLabels,
    required Project project,
  }) = ProjectDetailLoadSuccess;
}

class ProjectDetailBloc extends Bloc<ProjectDetailEvent, ProjectDetailState> {
  ProjectDetailBloc({
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    required LabelRepositoryContract labelRepository,
  }) : _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _labelRepository = labelRepository,
       super(const ProjectDetailState.initial()) {
    on<ProjectDetailEvent>((event, emit) async {
      await event.when(
        get: (projectId) async => _onGet(projectId, emit),
        update:
            (
              id,
              name,
              completed,
              description,
              startDate,
              deadlineDate,
              repeatIcalRrule,
              values,
              labels,
            ) async => _onUpdate(
              id: id,
              name: name,
              description: description,
              completed: completed,
              startDate: startDate,
              deadlineDate: deadlineDate,
              repeatIcalRrule: repeatIcalRrule,
              values: values,
              labels: labels,
              emit: emit,
            ),
        delete: (id) async => _onDelete(id, emit),
        create:
            (
              name,
              description,
              completed,
              startDate,
              deadlineDate,
              repeatIcalRrule,
              values,
              labels,
            ) async => _onCreate(
              name: name,
              description: description,
              completed: completed,
              startDate: startDate,
              deadlineDate: deadlineDate,
              repeatIcalRrule: repeatIcalRrule,
              values: values,
              labels: labels,
              emit: emit,
            ),
        loadInitialData: () async => _onLoadInitialData(emit),
      );
    });
  }
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final LabelRepositoryContract _labelRepository;

  Future<void> _onLoadInitialData(Emitter<ProjectDetailState> emit) async {
    emit(const ProjectDetailState.loadInProgress());
    try {
      final values = await _valueRepository.getAll();
      final labels = await _labelRepository.getAll();

      emit(
        ProjectDetailState.initialDataLoadSuccess(
          availableValues: values,
          availableLabels: labels,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future _onGet(
    String projectId,
    Emitter<ProjectDetailState> emit,
  ) async {
    emit(const ProjectDetailState.loadInProgress());
    try {
      final values = await _valueRepository.getAll();
      final labels = await _labelRepository.getAll();
      final project = await _projectRepository.get(
        projectId,
        withRelated: true,
      );
      if (project == null) {
        emit(
          const ProjectDetailState.operationFailure(
            errorDetails: ProjectDetailError(error: NotFoundEntity.project),
          ),
        );
      } else {
        emit(
          ProjectDetailState.loadSuccess(
            availableValues: values,
            availableLabels: labels,
            project: project,
          ),
        );
      }
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdate({
    required String id,
    required String name,
    required String? description,
    required bool completed,
    required DateTime? startDate,
    required DateTime? deadlineDate,
    required String? repeatIcalRrule,
    required List<ValueModel>? values,
    required List<Label>? labels,
    required Emitter<ProjectDetailState> emit,
  }) async {
    try {
      await _projectRepository.update(
        id: id,
        name: name,
        description: description,
        completed: completed,
        startDate: startDate,
        deadlineDate: deadlineDate,
        repeatIcalRrule: repeatIcalRrule,
        valueIds: values?.map((e) => e.id).toList(growable: false),
        labelIds: labels?.map((e) => e.id).toList(growable: false),
      );
      emit(
        ProjectDetailState.operationSuccess(
          operation: EntityOperation.update,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete(
    String id,
    Emitter<ProjectDetailState> emit,
  ) async {
    try {
      await _projectRepository.delete(id);
      emit(
        const ProjectDetailState.operationSuccess(
          operation: EntityOperation.delete,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate({
    required String name,
    required String? description,
    required bool completed,
    required DateTime? startDate,
    required DateTime? deadlineDate,
    required String? repeatIcalRrule,
    required List<ValueModel>? values,
    required List<Label>? labels,
    required Emitter<ProjectDetailState> emit,
  }) async {
    try {
      await _projectRepository.create(
        name: name,
        description: description,
        completed: completed,
        startDate: startDate,
        deadlineDate: deadlineDate,
        repeatIcalRrule: repeatIcalRrule,
        valueIds: values?.map((e) => e.id).toList(growable: false),
        labelIds: labels?.map((e) => e.id).toList(growable: false),
      );
      emit(
        const ProjectDetailState.operationSuccess(
          operation: EntityOperation.create,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ProjectDetailState.operationFailure(
          errorDetails: ProjectDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }
}
