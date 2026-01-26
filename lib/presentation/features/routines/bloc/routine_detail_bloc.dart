import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/bloc/detail_bloc_error.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/errors.dart';

part 'routine_detail_bloc.freezed.dart';

@freezed
sealed class RoutineDetailEvent with _$RoutineDetailEvent {
  const factory RoutineDetailEvent.loadForCreate() =
      _RoutineDetailLoadForCreate;
  const factory RoutineDetailEvent.loadById({
    required String routineId,
  }) = _RoutineDetailLoadById;
  const factory RoutineDetailEvent.create({
    required CreateRoutineCommand command,
  }) = _RoutineDetailCreate;
  const factory RoutineDetailEvent.update({
    required UpdateRoutineCommand command,
  }) = _RoutineDetailUpdate;
  const factory RoutineDetailEvent.delete({
    required String id,
  }) = _RoutineDetailDelete;
}

@freezed
sealed class RoutineDetailState with _$RoutineDetailState {
  const factory RoutineDetailState.initial() = RoutineDetailInitial;
  const factory RoutineDetailState.loadInProgress() = RoutineDetailLoadInProgress;
  const factory RoutineDetailState.initialDataLoadSuccess({
    required List<Project> availableProjects,
    required List<Value> availableValues,
  }) = RoutineDetailInitialDataLoadSuccess;
  const factory RoutineDetailState.loadSuccess({
    required List<Project> availableProjects,
    required List<Value> availableValues,
    required Routine routine,
  }) = RoutineDetailLoadSuccess;
  const factory RoutineDetailState.validationFailure({
    required ValidationFailure failure,
  }) = RoutineDetailValidationFailure;
  const factory RoutineDetailState.operationSuccess({
    required EntityOperation operation,
  }) = RoutineDetailOperationSuccess;
  const factory RoutineDetailState.operationFailure({
    required DetailBlocError<Routine> errorDetails,
  }) = RoutineDetailOperationFailure;
}

class RoutineDetailBloc
    extends Bloc<RoutineDetailEvent, RoutineDetailState>
    with DetailBlocMixin<RoutineDetailEvent, RoutineDetailState, Routine> {
  RoutineDetailBloc({
    required RoutineRepositoryContract routineRepository,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    required AppErrorReporter errorReporter,
    String? routineId,
  }) : _routineRepository = routineRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _errorReporter = errorReporter,
       _commandHandler = RoutineCommandHandler(
         routineRepository: routineRepository,
       ),
       super(const RoutineDetailState.initial()) {
    on<_RoutineDetailLoadForCreate>(_onLoadForCreate, transformer: restartable());
    on<_RoutineDetailLoadById>(_onLoadById, transformer: restartable());
    on<_RoutineDetailCreate>(_onCreate, transformer: droppable());
    on<_RoutineDetailUpdate>(_onUpdate, transformer: droppable());
    on<_RoutineDetailDelete>(_onDelete, transformer: droppable());

    if (routineId == null) {
      add(const RoutineDetailEvent.loadForCreate());
    } else {
      add(RoutineDetailEvent.loadById(routineId: routineId));
    }
  }

  final RoutineRepositoryContract _routineRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final AppErrorReporter _errorReporter;
  final RoutineCommandHandler _commandHandler;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? entityId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'routines',
      screen: 'routine_detail',
      intent: intent,
      operation: operation,
      entityType: 'routine',
      entityId: entityId,
      extraFields: extraFields,
    );
  }

  @override
  Talker get logger => talkerRaw;

  @override
  RoutineDetailState createLoadInProgressState() =>
      const RoutineDetailState.loadInProgress();

  @override
  RoutineDetailState createOperationSuccessState(EntityOperation operation) =>
      RoutineDetailState.operationSuccess(operation: operation);

  @override
  RoutineDetailState createOperationFailureState(
    DetailBlocError<Routine> error,
  ) =>
      RoutineDetailState.operationFailure(errorDetails: error);

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

  DetailBlocError<Routine> _toUiSafeError(
    Object error,
    StackTrace? stackTrace,
  ) {
    if (error is AppFailure) {
      return DetailBlocError<Routine>(
        error: error.uiMessage(),
        stackTrace: stackTrace,
      );
    }
    return DetailBlocError<Routine>(error: error, stackTrace: stackTrace);
  }

  Future<void> _onLoadForCreate(
    _RoutineDetailLoadForCreate event,
    Emitter<RoutineDetailState> emit,
  ) async {
    emit(const RoutineDetailState.loadInProgress());
    try {
      final results = await Future.wait([
        _projectRepository.getAll(),
        _valueRepository.getAll(),
      ]);
      final projects = results[0] as List<Project>;
      final values = results[1] as List<Value>;
      emit(
        RoutineDetailState.initialDataLoadSuccess(
          availableProjects: projects,
          availableValues: values,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        RoutineDetailState.operationFailure(
          errorDetails: DetailBlocError<Routine>(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _onLoadById(
    _RoutineDetailLoadById event,
    Emitter<RoutineDetailState> emit,
  ) async {
    emit(const RoutineDetailState.loadInProgress());
    try {
      final results = await Future.wait([
        _projectRepository.getAll(),
        _valueRepository.getAll(),
        _routineRepository.getById(event.routineId),
      ]);
      final projects = results[0] as List<Project>;
      final values = results[1] as List<Value>;
      final routine = results[2] as Routine?;
      if (routine == null) {
        emit(
          RoutineDetailState.operationFailure(
            errorDetails: const DetailBlocError(
              error: NotFoundEntity.routine,
            ),
          ),
        );
        return;
      }

      emit(
        RoutineDetailState.loadSuccess(
          availableProjects: projects,
          availableValues: values,
          routine: routine,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        RoutineDetailState.operationFailure(
          errorDetails: DetailBlocError<Routine>(
            error: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate(
    _RoutineDetailCreate event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'routine_create_requested',
      operation: 'routines.create',
    );
    await _executeValidatedCommand(
      emit,
      EntityOperation.create,
      () => _commandHandler.handleCreate(event.command, context: context),
      context: context,
    );
  }

  Future<void> _onUpdate(
    _RoutineDetailUpdate event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'routine_update_requested',
      operation: 'routines.update',
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
    _RoutineDetailDelete event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'routine_delete_requested',
      operation: 'routines.delete',
      entityId: event.id,
    );
    try {
      await _routineRepository.delete(event.id, context: context);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      emit(createOperationSuccessState(EntityOperation.delete));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Routine delete failed',
      );
      emit(createOperationFailureState(_toUiSafeError(error, stackTrace)));
    }
  }

  Future<void> _executeValidatedCommand(
    Emitter<RoutineDetailState> emit,
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
          emit(RoutineDetailState.validationFailure(failure: failure));
      }
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Routine ${operation.name} failed',
      );
      emit(createOperationFailureState(_toUiSafeError(error, stackTrace)));
    }
  }
}
