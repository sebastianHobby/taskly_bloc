import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/shared/bloc/detail_bloc_error.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/taskly_domain.dart';

part 'value_detail_bloc.freezed.dart';

@freezed
sealed class ValueDetailEvent with _$ValueDetailEvent {
  const factory ValueDetailEvent.update({
    required UpdateValueCommand command,
  }) = _ValueDetailUpdate;

  const factory ValueDetailEvent.delete({required String id}) =
      _ValueDetailDelete;

  const factory ValueDetailEvent.create({
    required CreateValueCommand command,
  }) = _ValueDetailCreate;

  const factory ValueDetailEvent.loadById({required String valueId}) =
      _ValueDetailLoadById;
}

@freezed
class ValueDetailState with _$ValueDetailState {
  const factory ValueDetailState.initial() = ValueDetailInitial;

  const factory ValueDetailState.validationFailure({
    required ValidationFailure failure,
  }) = ValueDetailValidationFailure;

  const factory ValueDetailState.operationSuccess({
    required EntityOperation operation,
  }) = ValueDetailOperationSuccess;
  const factory ValueDetailState.operationFailure({
    required DetailBlocError<Value> errorDetails,
  }) = ValueDetailOperationFailure;

  const factory ValueDetailState.loadInProgress() = ValueDetailLoadInProgress;
  const factory ValueDetailState.loadSuccess({required Value value}) =
      ValueDetailLoadSuccess;
}

class ValueDetailBloc extends Bloc<ValueDetailEvent, ValueDetailState>
    with DetailBlocMixin<ValueDetailEvent, ValueDetailState, Value> {
  ValueDetailBloc({
    required ValueRepositoryContract valueRepository,
    required AppErrorReporter errorReporter,
    String? valueId,
  }) : _valueRepository = valueRepository,
       _errorReporter = errorReporter,
       _commandHandler = ValueCommandHandler(valueRepository: valueRepository),
       super(const ValueDetailState.initial()) {
    on<_ValueDetailLoadById>(_onGet, transformer: restartable());
    on<_ValueDetailCreate>(_onCreate, transformer: droppable());
    on<_ValueDetailUpdate>(_onUpdate, transformer: droppable());
    on<_ValueDetailDelete>(_onDelete, transformer: droppable());

    if (valueId != null) {
      add(ValueDetailEvent.loadById(valueId: valueId));
    }
  }

  final ValueRepositoryContract _valueRepository;
  final AppErrorReporter _errorReporter;
  final ValueCommandHandler _commandHandler;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? entityId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'values',
      screen: 'value_detail',
      intent: intent,
      operation: operation,
      entityType: 'value',
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
  ValueDetailState createLoadInProgressState() =>
      const ValueDetailState.loadInProgress();

  @override
  ValueDetailState createOperationSuccessState(EntityOperation operation) =>
      ValueDetailState.operationSuccess(operation: operation);

  @override
  ValueDetailState createOperationFailureState(DetailBlocError<Value> error) =>
      ValueDetailState.operationFailure(errorDetails: error);

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

  DetailBlocError<Value> _toUiSafeError(Object error, StackTrace? stackTrace) {
    if (error is AppFailure) {
      return DetailBlocError<Value>(
        error: error.uiMessage(),
        stackTrace: stackTrace,
      );
    }

    return DetailBlocError<Value>(error: error, stackTrace: stackTrace);
  }

  Future<void> _onGet(
    _ValueDetailLoadById event,
    Emitter<ValueDetailState> emit,
  ) async {
    await executeLoadOperation(
      emit,
      load: () => _valueRepository.getById(event.valueId),
      onSuccess: (value) => ValueDetailState.loadSuccess(value: value),
      onNotFound: () => const DetailBlocError(error: NotFoundEntity.value),
    );
  }

  Future<void> _onCreate(
    _ValueDetailCreate event,
    Emitter<ValueDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'value_create_requested',
      operation: 'values.create',
    );
    await _executeValidatedCommand(
      emit,
      EntityOperation.create,
      () => _commandHandler.handleCreate(event.command, context: context),
      context: context,
    );
  }

  Future<void> _onUpdate(
    _ValueDetailUpdate event,
    Emitter<ValueDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'value_update_requested',
      operation: 'values.update',
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
    _ValueDetailDelete event,
    Emitter<ValueDetailState> emit,
  ) async {
    final context = _newContext(
      intent: 'value_delete_requested',
      operation: 'values.delete',
      entityId: event.id,
    );
    try {
      await _valueRepository.delete(event.id, context: context);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      emit(createOperationSuccessState(EntityOperation.delete));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Value delete failed',
      );
      emit(createOperationFailureState(_toUiSafeError(error, stackTrace)));
    }
  }

  Future<void> _executeValidatedCommand(
    Emitter<ValueDetailState> emit,
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
          emit(ValueDetailState.validationFailure(failure: failure));
      }
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: 'Value ${operation.name} failed',
      );
      emit(
        createOperationFailureState(
          _toUiSafeError(error, stackTrace),
        ),
      );
    }
  }
}
