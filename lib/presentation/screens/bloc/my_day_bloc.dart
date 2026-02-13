import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' show MyDayRitualStatus;
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart' show dateOnly;

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

sealed class MyDayEvent {
  const MyDayEvent();
}

final class MyDayStarted extends MyDayEvent {
  const MyDayStarted();
}

final class MyDayRoutineCompletionToggled extends MyDayEvent {
  const MyDayRoutineCompletionToggled({
    required this.routineId,
    required this.completedToday,
    required this.dayKeyUtc,
  });

  final String routineId;
  final bool completedToday;
  final DateTime dayKeyUtc;
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
    required this.completedPicks,
    required this.selectedTotalCount,
    required this.todaySelectedTaskIds,
    required this.todaySelectedRoutineIds,
    required this.ritualStatus,
  });

  final MyDaySummary summary;
  final MyDayMixVm mix;
  final List<Task> tasks;
  final List<MyDayPlannedItem> plannedItems;

  /// Tasks selected for today that are already completed.
  final List<Task> completedPicks;

  final int selectedTotalCount;

  /// Full set of task ids selected for today (from plan persistence).
  final Set<String> todaySelectedTaskIds;

  /// Full set of routine ids selected for today (from plan persistence).
  final Set<String> todaySelectedRoutineIds;

  final MyDayRitualStatus ritualStatus;
}

final class MyDayError extends MyDayState {
  const MyDayError(this.message);

  final String message;
}

final class MyDayBloc extends Bloc<MyDayEvent, MyDayState> {
  MyDayBloc({
    required MyDaySessionQueryService queryService,
    required RoutineWriteService routineWriteService,
    required NowService nowService,
    required DemoModeService demoModeService,
  }) : _queryService = queryService,
       _routineWriteService = routineWriteService,
       _nowService = nowService,
       _demoModeService = demoModeService,
       super(const MyDayLoading()) {
    on<MyDayStarted>(_onStarted, transformer: restartable());
    on<MyDayRoutineCompletionToggled>(
      _onRoutineCompletionToggled,
      transformer: droppable(),
    );
    add(const MyDayStarted());
  }

  final MyDaySessionQueryService _queryService;
  final RoutineWriteService _routineWriteService;
  final NowService _nowService;
  final DemoModeService _demoModeService;
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
        completedPicks: vm.completedPicks,
        selectedTotalCount: vm.selectedTotalCount,
        todaySelectedTaskIds: vm.todaySelectedTaskIds,
        todaySelectedRoutineIds: vm.todaySelectedRoutineIds,
        ritualStatus: vm.ritualStatus,
      ),
    );
  }

  Future<void> _onRoutineCompletionToggled(
    MyDayRoutineCompletionToggled event,
    Emitter<MyDayState> emit,
  ) async {
    if (_demoModeService.enabled.valueOrNull ?? false) return;
    if (event.completedToday) {
      final context = _contextFactory.create(
        feature: 'routines',
        screen: 'my_day',
        intent: 'routine_unlog',
        operation: 'routines.unlog',
        entityType: 'routine',
        entityId: event.routineId,
      );

      await _routineWriteService.removeLatestCompletionForDay(
        routineId: event.routineId,
        dayKeyUtc: event.dayKeyUtc,
        context: context,
      );
      return;
    }

    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'my_day',
      intent: 'routine_complete',
      operation: 'routines.complete',
      entityType: 'routine',
      entityId: event.routineId,
    );

    final nowLocal = _nowService.nowLocal();
    await _routineWriteService.recordCompletion(
      routineId: event.routineId,
      completedAtUtc: _nowService.nowUtc(),
      completedDayLocal: dateOnly(nowLocal),
      completedTimeLocalMinutes: nowLocal.hour * 60 + nowLocal.minute,
      context: context,
    );
  }
}
