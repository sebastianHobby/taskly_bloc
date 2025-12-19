import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';

// Events
abstract class ValueOverviewEvent {}

class ValuesSubscriptionRequested extends ValueOverviewEvent {}

// States
abstract class ValueOverviewState {}

class ValueOverviewInitial extends ValueOverviewState {}

class ValueOverviewLoading extends ValueOverviewState {}

class ValueOverviewLoaded extends ValueOverviewState {
  ValueOverviewLoaded({required this.values});
  final List<ValueTableData> values;
}

class ValueOverviewError extends ValueOverviewState {
  ValueOverviewError(this.message);
  final String message;
}

class ValueOverviewBloc extends Bloc<ValueOverviewEvent, ValueOverviewState> {
  ValueOverviewBloc({required ValueRepository valueRepository})
    : _valueRepository = valueRepository,
      super(ValueOverviewInitial()) {
    on<ValuesSubscriptionRequested>(_onSubscriptionRequested);
  }

  final ValueRepository _valueRepository;

  Future<void> _onSubscriptionRequested(
    ValuesSubscriptionRequested event,
    Emitter<ValueOverviewState> emit,
  ) async {
    emit(ValueOverviewLoading());
    await emit.forEach<List<ValueTableData>>(
      _valueRepository.getValues,
      onData: (values) => ValueOverviewLoaded(values: values),
      onError: (error, stack) => ValueOverviewError(error.toString()),
    );
  }
}
