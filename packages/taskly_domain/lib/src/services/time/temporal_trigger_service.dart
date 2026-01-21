import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/services/time/app_lifecycle_service.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/time/clock.dart';

sealed class TemporalTriggerEvent {
  const TemporalTriggerEvent();
}

/// Emitted when the app resumes.
///
/// This is useful for in-app-only time-based refreshes (e.g. attention rules)
/// without requiring a separate lifecycle subscription.
class AppResumed extends TemporalTriggerEvent {
  const AppResumed();
}

/// Emitted when the app's home-day key rolls over.
class HomeDayBoundaryCrossed extends TemporalTriggerEvent {
  const HomeDayBoundaryCrossed({required this.newDayKeyUtc});

  final DateTime newDayKeyUtc;
}

/// Centralized source of time-based domain events.
///
/// Currently emits day-boundary events based on the fixed home timezone offset.
/// This service also re-checks boundaries on app resume, since timers do not run
/// while the app is suspended.
class TemporalTriggerService {
  TemporalTriggerService({
    required HomeDayKeyService dayKeyService,
    required AppLifecycleService lifecycleService,
    Clock clock = systemClock,
  }) : _dayKeyService = dayKeyService,
       _lifecycleService = lifecycleService,
       _clock = clock;

  final HomeDayKeyService _dayKeyService;
  final AppLifecycleService _lifecycleService;
  final Clock _clock;

  final StreamController<TemporalTriggerEvent> _eventsController =
      StreamController<TemporalTriggerEvent>.broadcast();

  /// Broadcast stream of temporal triggers.
  ///
  /// Multiple coordinators/BLoCs are expected to listen concurrently.
  Stream<TemporalTriggerEvent> get events => _eventsController.stream;

  StreamSubscription<AppLifecycleEvent>? _lifecycleSub;
  Timer? _boundaryTimer;

  DateTime? _currentDayKeyUtc;

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _currentDayKeyUtc = _dayKeyService.todayDayKeyUtc(nowUtc: _clock.nowUtc());
    _scheduleNextBoundary();

    _lifecycleSub = _lifecycleService.events.listen((event) {
      if (event == AppLifecycleEvent.resumed) {
        _eventsController.add(const AppResumed());
        _checkForBoundaryCrossing(source: 'resume');
      }
    });
  }

  void stop() {
    if (!_started) return;
    _started = false;

    _boundaryTimer?.cancel();
    _boundaryTimer = null;

    _lifecycleSub?.cancel();
    _lifecycleSub = null;
  }

  Future<void> dispose() async {
    stop();
    await _eventsController.close();
  }

  void _scheduleNextBoundary() {
    _boundaryTimer?.cancel();

    final now = _clock.nowUtc();
    final nextBoundaryUtc = _dayKeyService.nextHomeDayBoundaryUtc(nowUtc: now);
    final delay = nextBoundaryUtc.difference(now);

    final clampedDelay = delay.isNegative ? Duration.zero : delay;

    talker.debug(
      '[TemporalTriggerService] scheduling day boundary in '
      '${clampedDelay.inMinutes}m (at $nextBoundaryUtc)',
    );

    _boundaryTimer = Timer(clampedDelay, () {
      _checkForBoundaryCrossing(source: 'timer');
      _scheduleNextBoundary();
    });
  }

  void _checkForBoundaryCrossing({required String source}) {
    final newKey = _dayKeyService.todayDayKeyUtc(nowUtc: _clock.nowUtc());
    final oldKey = _currentDayKeyUtc;

    if (oldKey == null || newKey.isAtSameMomentAs(oldKey)) {
      _currentDayKeyUtc = newKey;
      return;
    }

    _currentDayKeyUtc = newKey;
    talker.info(
      '[TemporalTriggerService] home day boundary crossed ($source): '
      '$oldKey -> $newKey',
    );

    _eventsController.add(HomeDayBoundaryCrossed(newDayKeyUtc: newKey));
  }
}
