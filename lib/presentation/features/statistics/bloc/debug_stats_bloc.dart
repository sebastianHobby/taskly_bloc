import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart';

enum DebugStatsRange { days7, days28, days90 }

@immutable
final class DebugStatsState {
  const DebugStatsState({
    this.loading = true,
    this.range = DebugStatsRange.days28,
    this.keepRates = const <MyDayShelfRate>[],
    this.deferRates = const <MyDayShelfRate>[],
    this.topDeferredTasks = const <MyDayEntityDeferCount>[],
    this.topDeferredRoutines = const <MyDayEntityDeferCount>[],
    this.routineWeekdays = const <RoutineWeekdayStat>[],
    this.lagMetrics = const <DeferredThenCompletedLagMetric>[],
    this.error,
  });

  final bool loading;
  final DebugStatsRange range;
  final List<MyDayShelfRate> keepRates;
  final List<MyDayShelfRate> deferRates;
  final List<MyDayEntityDeferCount> topDeferredTasks;
  final List<MyDayEntityDeferCount> topDeferredRoutines;
  final List<RoutineWeekdayStat> routineWeekdays;
  final List<DeferredThenCompletedLagMetric> lagMetrics;
  final Object? error;

  DebugStatsState copyWith({
    bool? loading,
    DebugStatsRange? range,
    List<MyDayShelfRate>? keepRates,
    List<MyDayShelfRate>? deferRates,
    List<MyDayEntityDeferCount>? topDeferredTasks,
    List<MyDayEntityDeferCount>? topDeferredRoutines,
    List<RoutineWeekdayStat>? routineWeekdays,
    List<DeferredThenCompletedLagMetric>? lagMetrics,
    Object? error = _sentinel,
  }) {
    return DebugStatsState(
      loading: loading ?? this.loading,
      range: range ?? this.range,
      keepRates: keepRates ?? this.keepRates,
      deferRates: deferRates ?? this.deferRates,
      topDeferredTasks: topDeferredTasks ?? this.topDeferredTasks,
      topDeferredRoutines: topDeferredRoutines ?? this.topDeferredRoutines,
      routineWeekdays: routineWeekdays ?? this.routineWeekdays,
      lagMetrics: lagMetrics ?? this.lagMetrics,
      error: identical(error, _sentinel) ? this.error : error,
    );
  }
}

const _sentinel = Object();

sealed class DebugStatsEvent {
  const DebugStatsEvent();
}

final class DebugStatsStarted extends DebugStatsEvent {
  const DebugStatsStarted();
}

final class DebugStatsRangeChanged extends DebugStatsEvent {
  const DebugStatsRangeChanged(this.range);
  final DebugStatsRange range;
}

final class DebugStatsBloc extends Bloc<DebugStatsEvent, DebugStatsState> {
  DebugStatsBloc({
    required MyDayDecisionEventRepositoryContract repository,
    required NowService nowService,
  }) : _repository = repository,
       _nowService = nowService,
       super(const DebugStatsState()) {
    on<DebugStatsStarted>(_onStarted);
    on<DebugStatsRangeChanged>(_onRangeChanged);
  }

  final MyDayDecisionEventRepositoryContract _repository;
  final NowService _nowService;

  Future<void> _onStarted(
    DebugStatsStarted event,
    Emitter<DebugStatsState> emit,
  ) async {
    await _load(emit, state.range);
  }

  Future<void> _onRangeChanged(
    DebugStatsRangeChanged event,
    Emitter<DebugStatsState> emit,
  ) async {
    await _load(emit, event.range);
  }

  Future<void> _load(Emitter<DebugStatsState> emit, DebugStatsRange range) async {
    emit(state.copyWith(loading: true, range: range, error: null));
    final now = _nowService.nowUtc();
    final days = switch (range) {
      DebugStatsRange.days7 => 7,
      DebugStatsRange.days28 => 28,
      DebugStatsRange.days90 => 90,
    };
    final dateRange = DateRange(
      start: now.subtract(Duration(days: days)),
      end: now,
    );
    try {
      final keepRates = await _repository.getKeepRateByShelf(range: dateRange);
      final deferRates = await _repository.getDeferRateByShelf(range: dateRange);
      final topDeferredTasks = await _repository.getEntityDeferCounts(
        range: dateRange,
        entityType: MyDayDecisionEntityType.task,
        limit: 10,
      );
      final topDeferredRoutines = await _repository.getEntityDeferCounts(
        range: dateRange,
        entityType: MyDayDecisionEntityType.routine,
        limit: 10,
      );
      final routineWeekdays = await _repository.getRoutineTopCompletionWeekdays(
        range: dateRange,
        topPerRoutine: 2,
        limitRoutines: 10,
      );
      final lagMetrics = await _repository.getDeferredThenCompletedLag(
        range: dateRange,
        limit: 10,
      );
      emit(
        state.copyWith(
          loading: false,
          range: range,
          keepRates: keepRates,
          deferRates: deferRates,
          topDeferredTasks: topDeferredTasks,
          topDeferredRoutines: topDeferredRoutines,
          routineWeekdays: routineWeekdays,
          lagMetrics: lagMetrics,
          error: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(loading: false, range: range, error: error));
    }
  }
}
