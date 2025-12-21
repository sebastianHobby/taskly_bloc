import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';

part 'label_detail_bloc.freezed.dart';

@freezed
sealed class LabelDetailEvent with _$LabelDetailEvent {
  const factory LabelDetailEvent.update({
    required String id,
    required String name,
    required String color,
  }) = _LabelDetailUpdate;

  const factory LabelDetailEvent.delete({required String id}) =
      _LabelDetailDelete;

  const factory LabelDetailEvent.create({
    required String name,
    required String color,
  }) = _LabelDetailCreate;

  const factory LabelDetailEvent.get({required String labelId}) =
      _LabelDetailGet;
}

@freezed
abstract class LabelDetailError with _$LabelDetailError {
  const factory LabelDetailError({
    required Object error,
    StackTrace? stackTrace,
  }) = _LabelDetailError;
}

@freezed
class LabelDetailState with _$LabelDetailState {
  const factory LabelDetailState.initial() = LabelDetailInitial;

  const factory LabelDetailState.operationSuccess({
    required EntityOperation operation,
  }) = LabelDetailOperationSuccess;
  const factory LabelDetailState.operationFailure({
    required LabelDetailError errorDetails,
  }) = LabelDetailOperationFailure;

  const factory LabelDetailState.loadInProgress() = LabelDetailLoadInProgress;
  const factory LabelDetailState.loadSuccess({required Label label}) =
      LabelDetailLoadSuccess;
}

class LabelDetailBloc extends Bloc<LabelDetailEvent, LabelDetailState> {
  LabelDetailBloc({
    required LabelRepositoryContract labelRepository,
    String? labelId,
  }) : _labelRepository = labelRepository,
       super(const LabelDetailState.initial()) {
    on<LabelDetailEvent>((event, emit) async {
      await event.when(
        get: (labelId) async => _onGet(labelId, emit),
        update: (id, name, color) async => _onUpdate(id, name, color, emit),
        delete: (id) async => _onDelete(id, emit),
        create: (name, color) async => _onCreate(name, color, emit),
      );
    });

    if (labelId != null) {
      add(LabelDetailEvent.get(labelId: labelId));
    }
  }

  final LabelRepositoryContract _labelRepository;

  Future<void> _onGet(String labelId, Emitter<LabelDetailState> emit) async {
    emit(const LabelDetailState.loadInProgress());
    try {
      final label = await _labelRepository.get(labelId);
      if (label == null) {
        emit(
          const LabelDetailState.operationFailure(
            errorDetails: LabelDetailError(error: NotFoundEntity.label),
          ),
        );
      } else {
        emit(LabelDetailState.loadSuccess(label: label));
      }
    } catch (error, stacktrace) {
      emit(
        LabelDetailState.operationFailure(
          errorDetails: LabelDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    String id,
    String name,
    String color,
    Emitter<LabelDetailState> emit,
  ) async {
    try {
      await _labelRepository.update(id: id, name: name, color: color);
      emit(
        const LabelDetailState.operationSuccess(
          operation: EntityOperation.update,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        LabelDetailState.operationFailure(
          errorDetails: LabelDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete(String id, Emitter<LabelDetailState> emit) async {
    try {
      await _labelRepository.delete(id);
      emit(
        const LabelDetailState.operationSuccess(
          operation: EntityOperation.delete,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        LabelDetailState.operationFailure(
          errorDetails: LabelDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate(
    String name,
    String color,
    Emitter<LabelDetailState> emit,
  ) async {
    try {
      await _labelRepository.create(name: name, color: color);
      emit(
        const LabelDetailState.operationSuccess(
          operation: EntityOperation.create,
        ),
      );
    } catch (error, stacktrace) {
      emit(
        LabelDetailState.operationFailure(
          errorDetails: LabelDetailError(
            error: error,
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }
}
