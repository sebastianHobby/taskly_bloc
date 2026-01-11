import 'dart:async';

import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/services/time/app_lifecycle_service.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';

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
  }) : _dayKeyService = dayKeyService,
       _lifecycleService = lifecycleService;

  final HomeDayKeyService _dayKeyService;
  final AppLifecycleService _lifecycleService;

  final StreamController<TemporalTriggerEvent> _eventsController =
      StreamController<TemporalTriggerEvent>.broadcast();

  Stream<TemporalTriggerEvent> get events => _eventsController.stream;

  StreamSubscription<AppLifecycleEvent>? _lifecycleSub;
  Timer? _boundaryTimer;

  DateTime? _currentDayKeyUtc;

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _currentDayKeyUtc = _dayKeyService.todayDayKeyUtc();
    _scheduleNextBoundary();

    _lifecycleSub = _lifecycleService.events.listen((event) {
      if (event == AppLifecycleEvent.resumed) {
        _eventsController.add(const AppResumed());
        _checkForBoundaryCrossing(source: 'resume');
      }
    });
  }

  Future<void> dispose() async {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;

    await _lifecycleSub?.cancel();
    _lifecycleSub = null;

    await _eventsController.close();
  }

  void _scheduleNextBoundary() {
    _boundaryTimer?.cancel();

    final now = DateTime.now().toUtc();
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
    final newKey = _dayKeyService.todayDayKeyUtc();
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
