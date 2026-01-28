import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_data/data_stack.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/core/services/time/app_lifecycle_service.dart';

/// Starts and stops the set of services that should only run once a user is
/// authenticated.
///
/// This is used to enforce "no data access before authentication" while still
/// allowing the app to keep running offline after a successful sign-in.
class AuthenticatedAppServicesCoordinator {
  AuthenticatedAppServicesCoordinator({
    required TasklyDataStack dataStack,
    required HomeDayKeyService homeDayKeyService,
    required AppLifecycleService appLifecycleService,
    required TemporalTriggerService temporalTriggerService,
    required AttentionTemporalInvalidationService
    attentionTemporalInvalidationService,
    required AttentionPrewarmService attentionPrewarmService,
  }) : _dataStack = dataStack,
       _homeDayKeyService = homeDayKeyService,
       _appLifecycleService = appLifecycleService,
       _temporalTriggerService = temporalTriggerService,
       _attentionTemporalInvalidationService =
           attentionTemporalInvalidationService,
       _attentionPrewarmService = attentionPrewarmService;

  final TasklyDataStack _dataStack;
  final HomeDayKeyService _homeDayKeyService;
  final AppLifecycleService _appLifecycleService;
  final TemporalTriggerService _temporalTriggerService;
  final AttentionTemporalInvalidationService
  _attentionTemporalInvalidationService;
  final AttentionPrewarmService _attentionPrewarmService;

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

      // Session lifecycle is owned by the app (DEC-032B).
      await _dataStack.startSession();

      await _homeDayKeyService.ensureInitialized();
      _homeDayKeyService.start();

      _appLifecycleService.start();
      _temporalTriggerService.start();

      _attentionTemporalInvalidationService.start();
      _attentionPrewarmService.start();

      _started = true;
    } finally {
      _startInFlight = null;
    }
  }

  Future<void> stop() async {
    await stopWithReason(reason: 'sign out', clearLocalData: true);
  }

  Future<void> stopWithReason({
    required String reason,
    required bool clearLocalData,
  }) async {
    // If start is in-flight, wait for it to settle so we don't race
    // with partial initialization.
    final inFlight = _startInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {
        // Ignore; we still attempt best-effort session shutdown.
      }
    }

    if (_started) {
      talker.info('[AuthServices] stopping post-auth services ($reason)');

      // Stop in reverse-ish order of dependencies.
      await _attentionPrewarmService.stop();
      _attentionTemporalInvalidationService.stop();
      _temporalTriggerService.stop();
      _appLifecycleService.stop();
      _homeDayKeyService.stop();

      _started = false;
    }

    await _dataStack.stopSession(
      reason: reason,
      clearLocalData: clearLocalData,
    );
    _startInFlight = null;
  }
}
