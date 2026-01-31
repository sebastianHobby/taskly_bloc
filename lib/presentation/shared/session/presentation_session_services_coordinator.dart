import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/features/projects/services/projects_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/scheduled/services/scheduled_session_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_allocation_cache_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

/// Starts/stops session-hot presentation services.
///
/// This sits in the Presentation layer so that core startup code does not need
/// to depend on presentation-only concerns.
final class PresentationSessionServicesCoordinator {
  PresentationSessionServicesCoordinator({
    required SessionDayKeyService sessionDayKeyService,
    required SessionStreamCacheManager sessionStreamCacheManager,
    required SessionSharedDataService sharedDataService,
    required SessionAllocationCacheService allocationCacheService,
    required MyDaySessionQueryService myDaySessionQueryService,
    required ScheduledSessionQueryService scheduledSessionQueryService,
    required ProjectsSessionQueryService projectsSessionQueryService,
  }) : _sessionDayKeyService = sessionDayKeyService,
       _sessionStreamCacheManager = sessionStreamCacheManager,
       _sharedDataService = sharedDataService,
       _allocationCacheService = allocationCacheService,
       _myDaySessionQueryService = myDaySessionQueryService,
       _scheduledSessionQueryService = scheduledSessionQueryService,
       _projectsSessionQueryService = projectsSessionQueryService;

  final SessionDayKeyService _sessionDayKeyService;
  final SessionStreamCacheManager _sessionStreamCacheManager;
  final SessionSharedDataService _sharedDataService;
  final SessionAllocationCacheService _allocationCacheService;
  final MyDaySessionQueryService _myDaySessionQueryService;
  final ScheduledSessionQueryService _scheduledSessionQueryService;
  final ProjectsSessionQueryService _projectsSessionQueryService;

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
      _sessionStreamCacheManager.start();
      _sessionDayKeyService.start();
      _sharedDataService.preloadDefaults();
      _allocationCacheService.start();
      _myDaySessionQueryService.start();
      _scheduledSessionQueryService.start();
      _projectsSessionQueryService.start();
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

    await _projectsSessionQueryService.stop();
    await _scheduledSessionQueryService.stop();
    await _myDaySessionQueryService.stop();
    await _allocationCacheService.stop();
    await _sharedDataService.stop();
    _sessionDayKeyService.stop();
    await _sessionStreamCacheManager.stop();

    _started = false;
    _startInFlight = null;
  }
}
