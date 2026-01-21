import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/scheduled/services/scheduled_session_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';

/// Starts/stops session-hot presentation services.
///
/// This sits in the Presentation layer so that core startup code does not need
/// to depend on presentation-only concerns.
final class PresentationSessionServicesCoordinator {
  PresentationSessionServicesCoordinator({
    required SessionDayKeyService sessionDayKeyService,
    required MyDaySessionQueryService myDaySessionQueryService,
    required ScheduledSessionQueryService scheduledSessionQueryService,
    required AnytimeSessionQueryService anytimeSessionQueryService,
  }) : _sessionDayKeyService = sessionDayKeyService,
       _myDaySessionQueryService = myDaySessionQueryService,
       _scheduledSessionQueryService = scheduledSessionQueryService,
       _anytimeSessionQueryService = anytimeSessionQueryService;

  final SessionDayKeyService _sessionDayKeyService;
  final MyDaySessionQueryService _myDaySessionQueryService;
  final ScheduledSessionQueryService _scheduledSessionQueryService;
  final AnytimeSessionQueryService _anytimeSessionQueryService;

  Future<void>? _startInFlight;
  bool _started = false;

  Future<void> start() {
    if (_started) return Future.value();
    return _startInFlight ??= _start();
  }

  Future<void> _start() async {
    if (_started) return;

    try {
      talker.info('[PresentationSession] starting session-hot services');
      _sessionDayKeyService.start();
      _myDaySessionQueryService.start();
      _scheduledSessionQueryService.start();
      _anytimeSessionQueryService.start();
      _started = true;
    } finally {
      _startInFlight = null;
    }
  }

  Future<void> stop() async {
    final inFlight = _startInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {
        // Best-effort stop.
      }
    }

    if (!_started) return;

    talker.info('[PresentationSession] stopping session-hot services');

    await _anytimeSessionQueryService.stop();
    await _scheduledSessionQueryService.stop();
    await _myDaySessionQueryService.stop();
    _sessionDayKeyService.stop();

    _started = false;
    _startInFlight = null;
  }
}
