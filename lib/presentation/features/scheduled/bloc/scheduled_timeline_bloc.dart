import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/services.dart';

sealed class ScheduledTimelineEvent {
  const ScheduledTimelineEvent();
}

final class _ScheduledTimelineOccurrencesUpdated
    extends ScheduledTimelineEvent {
  const _ScheduledTimelineOccurrencesUpdated({required this.result});

  final ScheduledOccurrencesResult result;
}

final class _ScheduledTimelineWatchFailed extends ScheduledTimelineEvent {
  const _ScheduledTimelineWatchFailed({required this.message});

  final String message;
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

final class ScheduledTimelineOverdueCollapsedToggled
    extends ScheduledTimelineEvent {
  const ScheduledTimelineOverdueCollapsedToggled();
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
    required this.overdueCollapsed,
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

  final bool overdueCollapsed;

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
    required ScheduledOccurrencesService occurrencesService,
    required SessionDayKeyService sessionDayKeyService,
    required NowService nowService,
    this.scope = const GlobalScheduledScope(),
  }) : _occurrencesService = occurrencesService,
        _sessionDayKeyService = sessionDayKeyService,
        _nowService = nowService,
        super(const ScheduledTimelineLoading()) {
    on<ScheduledTimelineStarted>(_onStarted);
    on<_ScheduledTimelineOccurrencesUpdated>(_onOccurrencesUpdated);
    on<_ScheduledTimelineWatchFailed>(_onWatchFailed);
    on<ScheduledTimelineVisibleDayChanged>(_onVisibleDayChanged);
    on<ScheduledTimelineDayJumpRequested>(_onDayJumpRequested);
    on<ScheduledTimelineOverdueCollapsedToggled>(_onOverdueCollapsedToggled);
    on<ScheduledTimelineScrollEffectHandled>(_onScrollEffectHandled);

    add(const ScheduledTimelineStarted());
  }

  final ScheduledOccurrencesService _occurrencesService;
  final SessionDayKeyService _sessionDayKeyService;
  final NowService _nowService;
  final ScheduledScope scope;

  final BehaviorSubject<_RangeWindow> _rangeWindow =
      BehaviorSubject<_RangeWindow>();
  StreamSubscription<ScheduledOccurrencesResult>? _watchSub;

  bool _overdueCollapsed = false;
  int _scrollToDaySignal = 0;
  DateTime? _scrollTargetDay;

  DateTime? _latestTodayUtc;
  DateTime? _latestTodayLocal;
  ScheduledOccurrencesResult? _latestResult;
  DateTime? _activeMonth;

  static const int _prefetchThresholdDays = 7;

  @override
  Future<void> close() async {
    await _watchSub?.cancel();
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

      final todayUtc = _sessionDayKeyService.todayDayKeyUtc.valueOrNull;
      final fallbackNow = _nowService.nowLocal();
      final effectiveTodayUtc =
          todayUtc ??
          DateTime.utc(
            fallbackNow.year,
            fallbackNow.month,
            fallbackNow.day,
          );

      _latestTodayUtc = effectiveTodayUtc;
      _latestTodayLocal = _toLocalDay(effectiveTodayUtc);
      _activeMonth = DateTime(
        _latestTodayLocal!.year,
        _latestTodayLocal!.month,
        1,
      );

      _rangeWindow.add(_initialWindowForToday(_latestTodayLocal!));

      await _watchSub?.cancel();
      _watchSub =
          Rx.combineLatest2<DateTime, _RangeWindow, _QueryParams>(
                _sessionDayKeyService.todayDayKeyUtc,
                _rangeWindow.distinct(),
                (todayDayKeyUtc, window) => _QueryParams(
                  todayUtc: todayDayKeyUtc,
                  startUtc: _toUtcDay(window.startDay),
                  endUtc: _toUtcDay(window.endDay),
                ),
              )
              .switchMap(
                (p) => _occurrencesService.watchScheduledOccurrences(
                  rangeStartDay: p.startUtc,
                  rangeEndDay: p.endUtc,
                  todayDayKeyUtc: p.todayUtc,
                  scope: scope,
                ),
              )
              .listen(
                (result) {
                  if (isClosed) return;
                  add(_ScheduledTimelineOccurrencesUpdated(result: result));
                },
                onError: (Object e, StackTrace _) {
                  if (isClosed) return;
                  add(_ScheduledTimelineWatchFailed(message: e.toString()));
                },
              );
    } catch (e) {
      emit(ScheduledTimelineError(message: e.toString()));
    }
  }

  void _onOccurrencesUpdated(
    _ScheduledTimelineOccurrencesUpdated event,
    Emitter<ScheduledTimelineState> emit,
  ) {
    _latestResult = event.result;
    _latestTodayUtc = _sessionDayKeyService.todayDayKeyUtc.valueOrNull;
    _latestTodayLocal = _latestTodayUtc == null
        ? _latestTodayLocal
        : _toLocalDay(_latestTodayUtc!);
    _emitLoaded(emit);
  }

  void _onWatchFailed(
    _ScheduledTimelineWatchFailed event,
    Emitter<ScheduledTimelineState> emit,
  ) {
    emit(ScheduledTimelineError(message: event.message));
  }

  void _emitLoaded(Emitter<ScheduledTimelineState> emit) {
    final result = _latestResult;
    final todayLocal = _latestTodayLocal;
    final window = _rangeWindow.valueOrNull;
    if (result == null || todayLocal == null || window == null) return;

    final activeMonth =
        _activeMonth ?? DateTime(todayLocal.year, todayLocal.month, 1);

    emit(
      ScheduledTimelineLoaded(
        today: todayLocal,
        rangeStartDay: window.startDay,
        rangeEndDay: window.endDay,
        activeMonth: activeMonth,
        occurrences: result.occurrences,
        overdue: result.overdue,
        overdueCollapsed: _overdueCollapsed,
        scrollToDaySignal: _scrollToDaySignal,
        scrollTargetDay: _scrollTargetDay,
      ),
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

    _emitLoaded(emit);
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

    _emitLoaded(emit);
  }

  Future<void> _onOverdueCollapsedToggled(
    ScheduledTimelineOverdueCollapsedToggled event,
    Emitter<ScheduledTimelineState> emit,
  ) async {
    _overdueCollapsed = !_overdueCollapsed;
    _emitLoaded(emit);
  }

  Future<void> _onScrollEffectHandled(
    ScheduledTimelineScrollEffectHandled event,
    Emitter<ScheduledTimelineState> emit,
  ) async {
    if (_scrollTargetDay == null) return;
    _scrollTargetDay = null;
    _emitLoaded(emit);
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
    required this.todayUtc,
    required this.startUtc,
    required this.endUtc,
  });

  final DateTime todayUtc;
  final DateTime startUtc;
  final DateTime endUtc;
}
