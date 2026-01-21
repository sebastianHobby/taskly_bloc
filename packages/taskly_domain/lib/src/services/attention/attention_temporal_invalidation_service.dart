import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/src/services/time/temporal_trigger_service.dart';

/// Emits in-app invalidation pulses for time-based attention rules.
///
/// This stays intentionally lightweight: attention evaluation remains pull-based
/// (sections call the evaluator when they render). This service exists so that
/// a section can re-render while the app is running, for example after the app
/// resumes or the home-day boundary changes.
class AttentionTemporalInvalidationService {
  AttentionTemporalInvalidationService({
    required TemporalTriggerService temporalTriggerService,
  }) : _temporalTriggerService = temporalTriggerService;

  final TemporalTriggerService _temporalTriggerService;

  final BehaviorSubject<void> _invalidationsSubject = BehaviorSubject<void>();

  /// Emits a value whenever attention should be re-evaluated.
  ///
  /// Stream contract:
  /// - broadcast: yes
  /// - replay: last (so late subscribers can evaluate immediately)
  /// - cold/hot: hot
  Stream<void> get invalidations => _invalidationsSubject.stream;

  StreamSubscription<TemporalTriggerEvent>? _sub;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _sub = _temporalTriggerService.events.listen((event) {
      if (event is HomeDayBoundaryCrossed || event is AppResumed) {
        _invalidationsSubject.add(null);
      }
    });

    // Initial pulse so first subscribers can load immediately.
    _invalidationsSubject.add(null);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    stop();
    await _invalidationsSubject.close();
  }
}
