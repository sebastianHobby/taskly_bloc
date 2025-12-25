import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/mixins/detail_bloc_mixin.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
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
    required LabelType type,
    String? iconName,
  }) = _LabelDetailUpdate;

  const factory LabelDetailEvent.delete({required String id}) =
      _LabelDetailDelete;

  const factory LabelDetailEvent.create({
    required String name,
    required String color,
    required LabelType type,
    String? iconName,
  }) = _LabelDetailCreate;

  const factory LabelDetailEvent.get({required String labelId}) =
      _LabelDetailGet;
}

@freezed
class LabelDetailState with _$LabelDetailState {
  const factory LabelDetailState.initial() = LabelDetailInitial;

  const factory LabelDetailState.operationSuccess({
    required EntityOperation operation,
  }) = LabelDetailOperationSuccess;
  const factory LabelDetailState.operationFailure({
    required DetailBlocError<Label> errorDetails,
  }) = LabelDetailOperationFailure;

  const factory LabelDetailState.loadInProgress() = LabelDetailLoadInProgress;
  const factory LabelDetailState.loadSuccess({required Label label}) =
      LabelDetailLoadSuccess;
}

class LabelDetailBloc extends Bloc<LabelDetailEvent, LabelDetailState>
    with DetailBlocMixin<LabelDetailEvent, LabelDetailState, Label> {
  LabelDetailBloc({
    required LabelRepositoryContract labelRepository,
    String? labelId,
  }) : _labelRepository = labelRepository,
       super(const LabelDetailState.initial()) {
    on<_LabelDetailGet>(_onGet);
    on<_LabelDetailCreate>(_onCreate);
    on<_LabelDetailUpdate>(_onUpdate);
    on<_LabelDetailDelete>(_onDelete);

    if (labelId != null) {
      add(LabelDetailEvent.get(labelId: labelId));
    }
  }

  final LabelRepositoryContract _labelRepository;

  @override
  final logger = AppLogger.forBloc('LabelDetail');

  @override
  Future<void> close() {
    // Defensive cleanup for page-scoped blocs
    return super.close();
  }

  // DetailBlocMixin implementation
  @override
  LabelDetailState createLoadInProgressState() =>
      const LabelDetailState.loadInProgress();

  @override
  LabelDetailState createOperationSuccessState(EntityOperation operation) =>
      LabelDetailState.operationSuccess(operation: operation);

  @override
  LabelDetailState createOperationFailureState(DetailBlocError<Label> error) =>
      LabelDetailState.operationFailure(errorDetails: error);

  Future<void> _onGet(
    _LabelDetailGet event,
    Emitter<LabelDetailState> emit,
  ) async {
    await executeLoadOperation(
      emit,
      load: () => _labelRepository.get(event.labelId),
      onSuccess: (label) => LabelDetailState.loadSuccess(label: label),
      onNotFound: () =>
          const DetailBlocError<Label>(error: NotFoundEntity.label),
    );
  }

  Future<void> _onUpdate(
    _LabelDetailUpdate event,
    Emitter<LabelDetailState> emit,
  ) async {
    await executeUpdateOperation(
      emit,
      () => _labelRepository.update(
        id: event.id,
        name: event.name,
        color: event.color,
        type: event.type,
        iconName: event.iconName,
      ),
    );
  }

  Future<void> _onDelete(
    _LabelDetailDelete event,
    Emitter<LabelDetailState> emit,
  ) async {
    await executeDeleteOperation(emit, () => _labelRepository.delete(event.id));
  }

  Future<void> _onCreate(
    _LabelDetailCreate event,
    Emitter<LabelDetailState> emit,
  ) async {
    await executeCreateOperation(
      emit,
      () => _labelRepository.create(
        name: event.name,
        color: event.color,
        type: event.type,
        iconName: event.iconName,
      ),
    );
  }
}
