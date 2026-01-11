import 'dart:async';

import 'package:taskly_bloc/domain/services/time/temporal_trigger_service.dart';

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

  final StreamController<void> _invalidationsController =
      StreamController<void>.broadcast();

  /// Emits a value whenever attention should be re-evaluated.
  Stream<void> get invalidations => _invalidationsController.stream;

  StreamSubscription<TemporalTriggerEvent>? _sub;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _sub = _temporalTriggerService.events.listen((event) {
      if (event is HomeDayBoundaryCrossed || event is AppResumed) {
        _invalidationsController.add(null);
      }
    });

    // Initial pulse so first subscribers can load immediately.
    _invalidationsController.add(null);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;

    await _invalidationsController.close();
  }
}
