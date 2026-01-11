import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/presentation/shared/bloc/detail_bloc_error.dart';
import 'package:taskly_bloc/domain/models/entity_operation.dart';
import 'package:taskly_bloc/domain/errors/not_found_entity.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';

part 'value_detail_bloc.freezed.dart';

@freezed
sealed class ValueDetailEvent with _$ValueDetailEvent {
  const factory ValueDetailEvent.update({
    required String id,
    required String name,
    required String color,
    required ValuePriority priority,
    String? iconName,
  }) = _ValueDetailUpdate;

  const factory ValueDetailEvent.delete({required String id}) =
      _ValueDetailDelete;

  const factory ValueDetailEvent.create({
    required String name,
    required String color,
    required ValuePriority priority,
    String? iconName,
  }) = _ValueDetailCreate;

  const factory ValueDetailEvent.loadById({required String valueId}) =
      _ValueDetailLoadById;
}

@freezed
class ValueDetailState with _$ValueDetailState {
  const factory ValueDetailState.initial() = ValueDetailInitial;

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
    String? valueId,
  }) : _valueRepository = valueRepository,
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

  @override
  Talker get logger => talker.raw;

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
    await executeOperation(
      emit,
      EntityOperation.create,
      () => _valueRepository.create(
        name: event.name,
        color: event.color,
        priority: event.priority,
        iconName: event.iconName,
      ),
    );
  }

  Future<void> _onUpdate(
    _ValueDetailUpdate event,
    Emitter<ValueDetailState> emit,
  ) async {
    await executeOperation(
      emit,
      EntityOperation.update,
      () => _valueRepository.update(
        id: event.id,
        name: event.name,
        color: event.color,
        priority: event.priority,
        iconName: event.iconName,
      ),
    );
  }

  Future<void> _onDelete(
    _ValueDetailDelete event,
    Emitter<ValueDetailState> emit,
  ) async {
    await executeOperation(
      emit,
      EntityOperation.delete,
      () => _valueRepository.delete(event.id),
    );
  }
}
