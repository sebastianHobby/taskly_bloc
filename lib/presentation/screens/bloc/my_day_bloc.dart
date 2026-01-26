import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';

sealed class MyDayEvent {
  const MyDayEvent();
}

final class MyDayStarted extends MyDayEvent {
  const MyDayStarted();
}

final class MyDayRoutineCompletionRequested extends MyDayEvent {
  const MyDayRoutineCompletionRequested({required this.routineId});

  final String routineId;
}

sealed class MyDayState {
  const MyDayState();
}

final class MyDayLoading extends MyDayState {
  const MyDayLoading();
}

final class MyDayLoaded extends MyDayState {
  const MyDayLoaded({
    required this.summary,
    required this.mix,
    required this.tasks,
    required this.plannedItems,
    required this.pinnedTasks,
    required this.completedPicks,
    required this.selectedTotalCount,
    required this.todaySelectedTaskIds,
    required this.todaySelectedRoutineIds,
  });

  final MyDaySummary summary;
  final MyDayMixVm mix;
  final List<Task> tasks;
  final List<MyDayPlannedItem> plannedItems;
  final List<Task> pinnedTasks;

  /// Tasks selected for today that are already completed.
  final List<Task> completedPicks;

  final int selectedTotalCount;

  /// Full set of task ids selected for today (from plan persistence).
  final Set<String> todaySelectedTaskIds;

  /// Full set of routine ids selected for today (from plan persistence).
  final Set<String> todaySelectedRoutineIds;
}

final class MyDayError extends MyDayState {
  const MyDayError(this.message);

  final String message;
}

final class MyDayBloc extends Bloc<MyDayEvent, MyDayState> {
  MyDayBloc({
    required MyDaySessionQueryService queryService,
    required RoutineRepositoryContract routineRepository,
    required NowService nowService,
  }) : _queryService = queryService,
       _routineRepository = routineRepository,
       _nowService = nowService,
       super(const MyDayLoading()) {
    on<MyDayStarted>(_onStarted, transformer: restartable());
    on<MyDayRoutineCompletionRequested>(
      _onRoutineCompletionRequested,
      transformer: droppable(),
    );
    add(const MyDayStarted());
  }

  final MyDaySessionQueryService _queryService;
  final RoutineRepositoryContract _routineRepository;
  final NowService _nowService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> _onStarted(MyDayStarted event, Emitter<MyDayState> emit) async {
    await emit.forEach<MyDayState>(
      _watchState(),
      onData: (state) => state,
      onError: (error, stackTrace) => MyDayError(
        'Failed to load My Day: $error',
      ),
    );
  }

  Stream<MyDayState> _watchState() {
    return _queryService.viewModel.map(
      (vm) => MyDayLoaded(
        summary: vm.summary,
        mix: vm.mix,
        tasks: vm.tasks,
        plannedItems: vm.plannedItems,
        pinnedTasks: vm.pinnedTasks,
        completedPicks: vm.completedPicks,
        selectedTotalCount: vm.selectedTotalCount,
        todaySelectedTaskIds: vm.todaySelectedTaskIds,
        todaySelectedRoutineIds: vm.todaySelectedRoutineIds,
      ),
    );
  }

  Future<void> _onRoutineCompletionRequested(
    MyDayRoutineCompletionRequested event,
    Emitter<MyDayState> emit,
  ) async {
    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'my_day',
      intent: 'routine_complete',
      operation: 'routines.complete',
      entityType: 'routine',
      entityId: event.routineId,
    );

    await _routineRepository.recordCompletion(
      routineId: event.routineId,
      completedAtUtc: _nowService.nowUtc(),
      context: context,
    );
  }
}
