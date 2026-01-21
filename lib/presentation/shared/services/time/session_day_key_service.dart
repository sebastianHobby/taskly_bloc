import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/services.dart';

/// Session-hot source of truth for "today" in day-key UTC.
///
/// This is intentionally lightweight and can keep running while the app is
/// backgrounded; heavy query services should pause their subscriptions on
/// background events.
final class SessionDayKeyService {
  SessionDayKeyService({
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
  }) : _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService;

  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;

  final BehaviorSubject<DateTime> _todayDayKeyUtc = BehaviorSubject<DateTime>();

  StreamSubscription<TemporalTriggerEvent>? _triggerSub;
  bool _started = false;

  /// Hot stream of today's day-key in UTC.
  ///
  /// Always replays the latest value to new subscribers.
  ValueStream<DateTime> get todayDayKeyUtc => _todayDayKeyUtc;

  void start() {
    if (_started) return;
    _started = true;

    _emitCurrent();

    _triggerSub = _temporalTriggerService.events
        .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
        .listen((_) => _emitCurrent());
  }

  void stop() {
    if (!_started) return;
    _started = false;
    unawaited(_triggerSub?.cancel());
    _triggerSub = null;
  }

  void _emitCurrent() {
    final next = _dayKeyService.todayDayKeyUtc();
    if (!_todayDayKeyUtc.isClosed) {
      _todayDayKeyUtc.add(next);
    }
  }

  Future<void> dispose() async {
    stop();
    await _todayDayKeyUtc.close();
  }
}
