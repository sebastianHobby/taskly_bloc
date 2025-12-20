import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/core/domain/domain.dart';
import 'package:taskly_bloc/data/repositories/contracts/value_repository_contract.dart';

// Events
abstract class ValueOverviewEvent {}

class ValuesSubscriptionRequested extends ValueOverviewEvent {}

// States
abstract class ValueOverviewState {}

class ValueOverviewInitial extends ValueOverviewState {}

class ValueOverviewLoading extends ValueOverviewState {}

class ValueOverviewLoaded extends ValueOverviewState {
  ValueOverviewLoaded({required this.values});
  final List<ValueModel> values;
}

class ValueOverviewError extends ValueOverviewState {
  ValueOverviewError(this.message);
  final String message;
}

class ValueOverviewBloc extends Bloc<ValueOverviewEvent, ValueOverviewState> {
  ValueOverviewBloc({required ValueRepositoryContract valueRepository})
    : _valueRepository = valueRepository,
      super(ValueOverviewInitial()) {
    on<ValuesSubscriptionRequested>(_onSubscriptionRequested);
  }

  final ValueRepositoryContract _valueRepository;

  Future<void> _onSubscriptionRequested(
    ValuesSubscriptionRequested event,
    Emitter<ValueOverviewState> emit,
  ) async {
    emit(ValueOverviewLoading());
    await emit.forEach<List<ValueModel>>(
      _valueRepository.watchAll(),
      onData: (values) => ValueOverviewLoaded(values: values),
      onError: (error, stack) => ValueOverviewError(error.toString()),
    );
  }
}
