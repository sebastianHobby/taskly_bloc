import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/taskly_domain.dart';

/// Starts and stops the set of services that should only run once a user is
/// authenticated.
///
/// This is used to enforce "no data access before authentication" while still
/// allowing the app to keep running offline after a successful sign-in.
class AuthenticatedAppServicesCoordinator {
  AuthenticatedAppServicesCoordinator({
    required HomeDayKeyService homeDayKeyService,
    required AppLifecycleService appLifecycleService,
    required TemporalTriggerService temporalTriggerService,
    required AttentionTemporalInvalidationService
    attentionTemporalInvalidationService,
    required AttentionPrewarmService attentionPrewarmService,
    required AllocationSnapshotCoordinator allocationSnapshotCoordinator,
  }) : _homeDayKeyService = homeDayKeyService,
       _appLifecycleService = appLifecycleService,
       _temporalTriggerService = temporalTriggerService,
       _attentionTemporalInvalidationService =
           attentionTemporalInvalidationService,
       _attentionPrewarmService = attentionPrewarmService,
       _allocationSnapshotCoordinator = allocationSnapshotCoordinator;

  final HomeDayKeyService _homeDayKeyService;
  final AppLifecycleService _appLifecycleService;
  final TemporalTriggerService _temporalTriggerService;
  final AttentionTemporalInvalidationService
  _attentionTemporalInvalidationService;
  final AttentionPrewarmService _attentionPrewarmService;
  final AllocationSnapshotCoordinator _allocationSnapshotCoordinator;

  Future<void>? _startInFlight;
  bool _started = false;

  Future<void> start() {
    if (_started) return Future.value();
    return _startInFlight ??= _start();
  }

  Future<void> _start() async {
    if (_started) return;

    try {
      talker.info('[AuthServices] starting post-auth services');

      await _homeDayKeyService.ensureInitialized();
      _homeDayKeyService.start();

      _appLifecycleService.start();
      _temporalTriggerService.start();

      _attentionTemporalInvalidationService.start();
      _attentionPrewarmService.start();

      _allocationSnapshotCoordinator.start();

      _started = true;
    } finally {
      _startInFlight = null;
    }
  }

  Future<void> stop() async {
    if (!_started) {
      _startInFlight = null;
      return;
    }

    talker.info('[AuthServices] stopping post-auth services');

    // Stop in reverse-ish order of dependencies.
    await _allocationSnapshotCoordinator.stop();
    await _attentionPrewarmService.stop();
    _attentionTemporalInvalidationService.stop();
    _temporalTriggerService.stop();
    _appLifecycleService.stop();
    _homeDayKeyService.stop();

    _started = false;
  }
}
