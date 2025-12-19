import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';

part 'value_detail_bloc.freezed.dart';

@freezed
sealed class ValueDetailEvent with _$ValueDetailEvent {
  const factory ValueDetailEvent.update({
    required String id,
    required String name,
  }) = _ValueDetailUpdate;

  const factory ValueDetailEvent.delete({
    required String id,
  }) = _ValueDetailDelete;

  const factory ValueDetailEvent.create({
    required String name,
  }) = _ValueDetailCreate;

  const factory ValueDetailEvent.get({required String valueId}) =
      _ValueDetailGet;
}

@freezed
abstract class ValueDetailError with _$ValueDetailError {
  const factory ValueDetailError({
    required String message,
    StackTrace? stackTrace,
  }) = _ValueDetailError;
}

@freezed
class ValueDetailState with _$ValueDetailState {
  const factory ValueDetailState.initial() = ValueDetailInitial;

  const factory ValueDetailState.operationSuccess({required String message}) =
      ValueDetailOperationSuccess;
  const factory ValueDetailState.operationFailure({
    required ValueDetailError errorDetails,
  }) = ValueDetailOperationFailure;

  const factory ValueDetailState.loadInProgress() = ValueDetailLoadInProgress;
  const factory ValueDetailState.loadSuccess({
    required ValueTableData value,
  }) = ValueDetailLoadSuccess;
}

class ValueDetailBloc extends Bloc<ValueDetailEvent, ValueDetailState> {
  ValueDetailBloc({required ValueRepository valueRepository, String? valueId})
    : _valueRepository = valueRepository,
      super(const ValueDetailState.initial()) {
    on<ValueDetailEvent>((event, emit) async {
      await event.when(
        get: (valueId) async => _onGet(valueId, emit),
        update: (id, name) async => _onUpdate(id, name, emit),
        delete: (id) async => _onDelete(id, emit),
        create: (name) async => _onCreate(name, emit),
      );
    });

    if (valueId != null) {
      add(ValueDetailEvent.get(valueId: valueId));
    }
  }

  final ValueRepository _valueRepository;

  Future _onGet(String valueId, Emitter<ValueDetailState> emit) async {
    emit(const ValueDetailState.loadInProgress());
    try {
      final value = await _valueRepository.getValueById(valueId);
      if (value == null) {
        emit(
          const ValueDetailState.operationFailure(
            errorDetails: ValueDetailError(message: 'Value not found'),
          ),
        );
      } else {
        emit(ValueDetailState.loadSuccess(value: value));
      }
    } catch (error, stacktrace) {
      emit(
        ValueDetailState.operationFailure(
          errorDetails: ValueDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    String id,
    String name,
    Emitter<ValueDetailState> emit,
  ) async {
    final updateCompanion = ValueTableCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _valueRepository.updateValue(updateCompanion);
      emit(
        ValueDetailState.operationSuccess(
          message: 'Value updated successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ValueDetailState.operationFailure(
          errorDetails: ValueDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete(
    String id,
    Emitter<ValueDetailState> emit,
  ) async {
    final deleteCompanion = ValueTableCompanion(
      id: Value(id),
    );
    try {
      await _valueRepository.deleteValue(deleteCompanion);
      emit(
        const ValueDetailState.operationSuccess(
          message: 'Value deleted successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ValueDetailState.operationFailure(
          errorDetails: ValueDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate(
    String name,
    Emitter<ValueDetailState> emit,
  ) async {
    final createCompanion = ValueTableCompanion(
      name: Value(name),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _valueRepository.createValue(createCompanion);
      emit(
        const ValueDetailState.operationSuccess(
          message: 'Value created successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        ValueDetailState.operationFailure(
          errorDetails: ValueDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }
}
