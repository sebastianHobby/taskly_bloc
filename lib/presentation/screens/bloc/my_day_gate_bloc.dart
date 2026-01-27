import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_gate_query_service.dart';

sealed class MyDayGateState {
  const MyDayGateState();
}

final class MyDayGateLoading extends MyDayGateState {
  const MyDayGateLoading();
}

final class MyDayGateLoaded extends MyDayGateState {
  const MyDayGateLoaded({
    required this.needsValuesSetup,
  });

  final bool needsValuesSetup;
}

final class MyDayGateError extends MyDayGateState {
  const MyDayGateError(this.message);

  final String message;
}

sealed class MyDayGateEvent {
  const MyDayGateEvent();
}

final class MyDayGateStarted extends MyDayGateEvent {
  const MyDayGateStarted();
}

final class MyDayGateRetryRequested extends MyDayGateEvent {
  const MyDayGateRetryRequested();
}

class MyDayGateBloc extends Bloc<MyDayGateEvent, MyDayGateState> {
  MyDayGateBloc({
    required MyDayGateQueryService queryService,
  }) : _queryService = queryService,
       super(const MyDayGateLoading()) {
    on<MyDayGateStarted>(_onStarted, transformer: restartable());
    on<MyDayGateRetryRequested>(_onRetryRequested, transformer: restartable());

    add(const MyDayGateStarted());
  }

  final MyDayGateQueryService _queryService;

  Future<void> _onStarted(
    MyDayGateStarted event,
    Emitter<MyDayGateState> emit,
  ) async {
    await _subscribe(emit);
  }

  Future<void> _onRetryRequested(
    MyDayGateRetryRequested event,
    Emitter<MyDayGateState> emit,
  ) async {
    emit(const MyDayGateLoading());
    await _subscribe(emit);
  }

  Future<void> _subscribe(Emitter<MyDayGateState> emit) async {
    await emit.forEach<bool>(
      _queryService.watchNeedsValuesSetup(),
      onData: (needsValuesSetup) => MyDayGateLoaded(
        needsValuesSetup: needsValuesSetup,
      ),
      onError: (error, stackTrace) =>
          MyDayGateError('Failed to load My Day prerequisites: $error'),
    );
  }
}
