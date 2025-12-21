import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';

part 'value_list_bloc.freezed.dart';

@freezed
sealed class ValueOverviewEvent with _$ValueOverviewEvent {
  const factory ValueOverviewEvent.valuesSubscriptionRequested() =
      ValuesSubscriptionRequested;
}

@freezed
sealed class ValueOverviewState with _$ValueOverviewState {
  const factory ValueOverviewState.initial() = ValueOverviewInitial;
  const factory ValueOverviewState.loading() = ValueOverviewLoading;
  const factory ValueOverviewState.loaded({required List<ValueModel> values}) =
      ValueOverviewLoaded;
  const factory ValueOverviewState.error({required Object error}) =
      ValueOverviewError;
}

class ValueOverviewBloc extends Bloc<ValueOverviewEvent, ValueOverviewState> {
  ValueOverviewBloc({required ValueRepositoryContract valueRepository})
    : _valueRepository = valueRepository,
      super(const ValueOverviewInitial()) {
    on<ValuesSubscriptionRequested>(_onSubscriptionRequested);
  }

  final ValueRepositoryContract _valueRepository;

  Future<void> _onSubscriptionRequested(
    ValuesSubscriptionRequested event,
    Emitter<ValueOverviewState> emit,
  ) async {
    emit(const ValueOverviewLoading());
    await emit.forEach<List<ValueModel>>(
      _valueRepository.watchAll(),
      onData: (values) => ValueOverviewLoaded(values: values),
      onError: (error, stack) => ValueOverviewError(error: error),
    );
  }
}
