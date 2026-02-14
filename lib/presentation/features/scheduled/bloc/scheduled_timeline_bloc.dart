import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/scheduled/services/scheduled_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/services.dart';

sealed class ScheduledTimelineEvent {
  const ScheduledTimelineEvent();
}

final class ScheduledTimelineStarted extends ScheduledTimelineEvent {
  const ScheduledTimelineStarted();
}

final class ScheduledTimelineVisibleDayChanged extends ScheduledTimelineEvent {
  const ScheduledTimelineVisibleDayChanged({required this.day});

  /// Local date-only semantics.
  final DateTime day;
}

final class ScheduledTimelineDayJumpRequested extends ScheduledTimelineEvent {
  const ScheduledTimelineDayJumpRequested({required this.day});

  /// Local date-only semantics.
  final DateTime day;
}

final class ScheduledTimelineScrollEffectHandled
    extends ScheduledTimelineEvent {
  const ScheduledTimelineScrollEffectHandled();
}

@immutable
sealed class ScheduledTimelineState {
  const ScheduledTimelineState();
}

final class ScheduledTimelineLoading extends ScheduledTimelineState {
  const ScheduledTimelineLoading();
}

final class ScheduledTimelineLoaded extends ScheduledTimelineState {
  const ScheduledTimelineLoaded({
    required this.today,
    required this.rangeStartDay,
    required this.rangeEndDay,
    required this.activeMonth,
    required this.occurrences,
    required this.overdue,
    required this.scrollToDaySignal,
    required this.scrollTargetDay,
  });

  /// Local date-only semantics.
  final DateTime today;

  /// Local date-only semantics.
  final DateTime rangeStartDay;

  /// Local date-only semantics.
  final DateTime rangeEndDay;

  /// First day of month (local date-only semantics).
  final DateTime activeMonth;

  final List<ScheduledOccurrence> overdue;

  /// Scheduled occurrences within the current range.
  final List<ScheduledOccurrence> occurrences;

  /// Monotonically increasing signal used by the UI to trigger a one-off scroll.
  final int scrollToDaySignal;

  /// Local day to scroll to when [scrollToDaySignal] changes.
  final DateTime? scrollTargetDay;
}

final class ScheduledTimelineError extends ScheduledTimelineState {
  const ScheduledTimelineError({required this.message});

  final String message;
}

final class ScheduledTimelineBloc
    extends Bloc<ScheduledTimelineEvent, ScheduledTimelineState> {
  ScheduledTimelineBloc({
    required ScheduledSessionQueryService queryService,
    required SessionDayKeyService sessionDayKeyService,
    required NowService nowService,
    required DemoModeService demoModeService,
    this.scope = const GlobalScheduledScope(),
  }) : _queryService = queryService,
       _sessionDayKeyService = sessionDayKeyService,
       _nowService = nowService,
       _demoModeService = demoModeService,
       super(const ScheduledTimelineLoading()) {
    on<ScheduledTimelineStarted>(_onStarted, transformer: restartable());
    on<ScheduledTimelineVisibleDayChanged>(_onVisibleDayChanged);
    on<ScheduledTimelineDayJumpRequested>(_onDayJumpRequested);
    on<ScheduledTimelineScrollEffectHandled>(_onScrollEffectHandled);

    add(const ScheduledTimelineStarted());
  }

  final ScheduledSessionQueryService _queryService;
  final SessionDayKeyService _sessionDayKeyService;
  final NowService _nowService;
  final DemoModeService _demoModeService;
  final ScheduledScope scope;

  final BehaviorSubject<_RangeWindow> _rangeWindow =
      BehaviorSubject<_RangeWindow>();

  int _scrollToDaySignal = 0;
  DateTime? _scrollTargetDay;

  DateTime? _latestTodayUtc;
  DateTime? _latestTodayLocal;
  ScheduledOccurrencesResult? _latestResult;
  DateTime? _activeMonth;

  static const int _prefetchThresholdDays = 7;

  @override
  Future<void> close() async {
    await _rangeWindow.close();
    return super.close();
  }

  Future<void> _onStarted(
    ScheduledTimelineStarted event,
    Emitter<ScheduledTimelineState> emit,
  ) async {
    try {
      // The timeline depends on a session-hot "today" stream.
      // If the service isn't started yet, the stream won't emit and the UI will
      // remain in loading indefinitely.
      _sessionDayKeyService.start();

      final demoEnabled = _demoModeService.enabled.valueOrNull ?? false;
      final todayUtc = _sessionDayKeyService.todayDayKeyUtc.valueOrNull;
      final fallbackNow = _nowService.nowLocal();
      final effectiveTodayUtc = demoEnabled
          ? DemoDataProvider.demoDayKeyUtc
          : (todayUtc ??
                DateTime.utc(
                  fallbackNow.year,
                  fallbackNow.month,
                  fallbackNow.day,
                ));

      _latestTodayUtc = effectiveTodayUtc;
      _latestTodayLocal = _toLocalDay(effectiveTodayUtc);
      _activeMonth = DateTime(
        _latestTodayLocal!.year,
        _latestTodayLocal!.month,
        1,
      );

      _rangeWindow.add(_initialWindowForToday(_latestTodayLocal!));

      final params$ = Rx.combineLatest2<DateTime, _RangeWindow, _QueryParams>(
        _sessionDayKeyService.todayDayKeyUtc,
        _rangeWindow.distinct(),
        (_, window) => _QueryParams(
          startUtc: _toUtcDay(window.startDay),
          endUtc: _toUtcDay(window.endDay),
        ),
      );

      final occurrences$ = params$.switchMap(
        (p) => _queryService.watchScheduledOccurrences(
          scope: scope,
          rangeStartDay: p.startUtc,
          rangeEndDay: p.endUtc,
        ),
      );

      await emit.forEach<ScheduledOccurrencesResult>(
        occurrences$,
        onData: (result) {
          _latestResult = result;
          final demoEnabled = _demoModeService.enabled.valueOrNull ?? false;
          _latestTodayUtc = demoEnabled
              ? DemoDataProvider.demoDayKeyUtc
              : _sessionDayKeyService.todayDayKeyUtc.valueOrNull;
          _latestTodayLocal = _latestTodayUtc == null
              ? _latestTodayLocal
              : _toLocalDay(_latestTodayUtc!);
          return _buildLoadedState() ?? state;
        },
        onError: (error, stackTrace) =>
            ScheduledTimelineError(message: error.toString()),
      );
    } catch (e) {
      emit(ScheduledTimelineError(message: e.toString()));
    }
  }

  ScheduledTimelineState? _buildLoadedState() {
    final result = _latestResult;
    final todayLocal = _latestTodayLocal;
    final window = _rangeWindow.valueOrNull;
    if (result == null || todayLocal == null || window == null) return null;

    final activeMonth =
        _activeMonth ?? DateTime(todayLocal.year, todayLocal.month, 1);

    return ScheduledTimelineLoaded(
      today: todayLocal,
      rangeStartDay: window.startDay,
      rangeEndDay: window.endDay,
      activeMonth: activeMonth,
      occurrences: result.occurrences,
      overdue: result.overdue,
      scrollToDaySignal: _scrollToDaySignal,
      scrollTargetDay: _scrollTargetDay,
    );
  }

  Future<void> _onVisibleDayChanged(
    ScheduledTimelineVisibleDayChanged event,
    Emitter<ScheduledTimelineState> emit,
  ) async {
    final day = _toLocalDay(event.day);
    _activeMonth = DateTime(day.year, day.month, 1);

    final window = _rangeWindow.valueOrNull;
    if (window != null) {
      final nearEnd = !day.isBefore(
        window.endDay.subtract(
          const Duration(days: _prefetchThresholdDays),
        ),
      );

      if (nearEnd) {
        _rangeWindow.add(_extendWindowFuture(window));
      }
    }

    final next = _buildLoadedState();
    if (next != null) emit(next);
  }

  Future<void> _onDayJumpRequested(
    ScheduledTimelineDayJumpRequested event,
    Emitter<ScheduledTimelineState> emit,
  ) async {
    final today = _latestTodayLocal;
    if (today == null) return;

    final requestedDay = _toLocalDay(event.day);
    final targetDay = requestedDay.isBefore(today) ? today : requestedDay;
    final targetMonth = DateTime(targetDay.year, targetDay.month, 1);

    final window = _rangeWindow.valueOrNull;
    if (window != null) {
      final desired = _ensureWindowCoversMonth(window, targetMonth);
      if (desired != window) {
        _rangeWindow.add(desired);
      }
    }

    _activeMonth = targetMonth;
    _scrollTargetDay = targetDay;
    _scrollToDaySignal++;

    final next = _buildLoadedState();
    if (next != null) emit(next);
  }

  Future<void> _onScrollEffectHandled(
    ScheduledTimelineScrollEffectHandled event,
    Emitter<ScheduledTimelineState> emit,
  ) async {
    if (_scrollTargetDay == null) return;
    _scrollTargetDay = null;
    final next = _buildLoadedState();
    if (next != null) emit(next);
  }

  static DateTime _toLocalDay(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  static DateTime _toUtcDay(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day);

  static _RangeWindow _initialWindowForToday(DateTime today) {
    // Scheduled timeline never renders dates before today.
    final start = today;
    final end = DateTime(today.year, today.month + 2, 0);
    return _RangeWindow(startDay: _toLocalDay(start), endDay: _toLocalDay(end));
  }

  static _RangeWindow _extendWindowFuture(_RangeWindow window) {
    final nextEnd = DateTime(window.endDay.year, window.endDay.month + 2, 0);
    return _RangeWindow(
      startDay: window.startDay,
      endDay: _toLocalDay(nextEnd),
    );
  }

  static _RangeWindow _ensureWindowCoversMonth(
    _RangeWindow window,
    DateTime monthStart,
  ) {
    final desiredEnd = DateTime(monthStart.year, monthStart.month + 2, 0);
    final end = window.endDay.isBefore(desiredEnd) ? desiredEnd : window.endDay;

    // Start day is always anchored to today.
    return _RangeWindow(startDay: window.startDay, endDay: _toLocalDay(end));
  }
}

@immutable
final class _RangeWindow {
  const _RangeWindow({required this.startDay, required this.endDay});

  final DateTime startDay;
  final DateTime endDay;

  @override
  bool operator ==(Object other) {
    return other is _RangeWindow &&
        other.startDay == startDay &&
        other.endDay == endDay;
  }

  @override
  int get hashCode => Object.hash(startDay, endDay);
}

@immutable
final class _QueryParams {
  const _QueryParams({
    required this.startUtc,
    required this.endUtc,
  });

  final DateTime startUtc;
  final DateTime endUtc;
}
