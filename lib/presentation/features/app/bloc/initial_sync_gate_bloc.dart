import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_bloc/presentation/shared/session/presentation_session_services_coordinator.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

sealed class InitialSyncGateEvent {
  const InitialSyncGateEvent();
}

final class InitialSyncGateStarted extends InitialSyncGateEvent {
  const InitialSyncGateStarted();
}

final class InitialSyncGateRetryRequested extends InitialSyncGateEvent {
  const InitialSyncGateRetryRequested();
}

sealed class InitialSyncGateState {
  const InitialSyncGateState();
}

final class InitialSyncGateInProgress extends InitialSyncGateState {
  const InitialSyncGateInProgress({required this.progress});

  final InitialSyncProgress? progress;
}

final class InitialSyncGateFailure extends InitialSyncGateState {
  const InitialSyncGateFailure({required this.message, required this.progress});

  final String message;
  final InitialSyncProgress? progress;
}

final class InitialSyncGateReady extends InitialSyncGateState {
  const InitialSyncGateReady();
}

final class InitialSyncGateBloc
    extends Bloc<InitialSyncGateEvent, InitialSyncGateState> {
  InitialSyncGateBloc({
    required AuthenticatedAppServicesCoordinator coordinator,
    required PresentationSessionCoordinator presentationSessionCoordinator,
    required InitialSyncService initialSyncService,
    required SessionSharedDataService sharedDataService,
    Duration initialProgressTimeout = const Duration(seconds: 15),
    Duration localProbeTimeout = const Duration(seconds: 5),
  }) : _coordinator = coordinator,
       _presentationSessionCoordinator = presentationSessionCoordinator,
       _initialSyncService = initialSyncService,
       _sharedDataService = sharedDataService,
       _initialProgressTimeout = initialProgressTimeout,
       _localProbeTimeout = localProbeTimeout,
       super(const InitialSyncGateInProgress(progress: null)) {
    on<InitialSyncGateStarted>(_onStarted, transformer: restartable());
    on<InitialSyncGateRetryRequested>(_onRetryRequested);
  }

  final AuthenticatedAppServicesCoordinator _coordinator;
  final PresentationSessionCoordinator _presentationSessionCoordinator;
  final InitialSyncService _initialSyncService;
  final SessionSharedDataService _sharedDataService;
  final Duration _initialProgressTimeout;
  final Duration _localProbeTimeout;

  Future<void> _onStarted(
    InitialSyncGateStarted event,
    Emitter<InitialSyncGateState> emit,
  ) async {
    emit(const InitialSyncGateInProgress(progress: null));
    await emit.forEach<InitialSyncGateState>(
      _gateStateStream(),
      onData: (state) => state,
      onError: (error, stackTrace) {
        return InitialSyncGateFailure(
          message: 'Failed to sync data: $error',
          progress: null,
        );
      },
    );
  }

  Future<void> _onRetryRequested(
    InitialSyncGateRetryRequested event,
    Emitter<InitialSyncGateState> emit,
  ) async {
    add(const InitialSyncGateStarted());
  }

  Stream<InitialSyncGateState> _gateStateStream() async* {
    final startupId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      AppLog.routineStructured(
        'startup.sync_gate',
        'startup stage',
        fields: <String, Object?>{
          'stage': 'start_authenticated_services',
          'startupId': startupId,
        },
      );
      await _coordinator.start();
      await _presentationSessionCoordinator.start();
    } catch (e, st) {
      AppLog.handleStructured(
        'startup.sync_gate',
        'startup stage failed',
        e,
        st,
        <String, Object?>{
          'stage': 'start_authenticated_services',
          'startupId': startupId,
        },
      );
      yield InitialSyncGateFailure(
        message: 'Failed to start sync session: $e',
        progress: null,
      );
      return;
    }

    try {
      AppLog.routineStructured(
        'startup.sync_gate',
        'startup stage',
        fields: <String, Object?>{
          'stage': 'await_initial_sync_progress',
          'startupId': startupId,
          'timeoutMs': _initialProgressTimeout.inMilliseconds,
        },
      );
      final initial = await _readInitialProgress();
      if (initial == null) {
        final hasLocalData = await _hasLocalDataWithTimeout(startupId);
        if (hasLocalData ?? false) {
          AppLog.warnStructured(
            'startup.sync_gate',
            'initial sync progress timeout; allowing app with local data',
            fields: <String, Object?>{
              'startupId': startupId,
            },
          );
          yield const InitialSyncGateReady();
          return;
        }

        yield const InitialSyncGateFailure(
          message:
              'Sync is taking longer than expected. Please retry and check your connection.',
          progress: null,
        );
        return;
      }

      final shouldBlock = await _shouldBlock(initial);
      if (!shouldBlock) {
        AppLog.routineStructured(
          'startup.sync_gate',
          'startup stage',
          fields: <String, Object?>{
            'stage': 'gate_ready_without_block',
            'startupId': startupId,
          },
        );
        yield const InitialSyncGateReady();
        return;
      }

      yield InitialSyncGateInProgress(progress: initial);

      await for (final progress in _initialSyncService.progress) {
        yield InitialSyncGateInProgress(progress: progress);

        if (progress.hasSynced) {
          yield const InitialSyncGateReady();
          return;
        }
      }

      yield const InitialSyncGateReady();
    } catch (e, st) {
      AppLog.handleStructured(
        'startup.sync_gate',
        'startup stage failed',
        e,
        st,
        <String, Object?>{
          'stage': 'wait_for_sync_progress_stream',
          'startupId': startupId,
        },
      );
      yield InitialSyncGateFailure(
        message: 'Failed while waiting for sync: $e',
        progress: null,
      );
    }
  }

  Future<bool> _shouldBlock(InitialSyncProgress progress) async {
    final hasCheckpoint = progress.hasSynced || progress.lastSyncedAt != null;
    if (hasCheckpoint) return false;

    final hasLocalData = await _hasLocalDataWithTimeout();
    if (hasLocalData == null) {
      AppLog.warnStructured(
        'startup.sync_gate',
        'local data probe timed out; allowing app to avoid setup deadlock',
        fields: const <String, Object?>{},
      );
      return false;
    }

    return !hasLocalData;
  }

  Future<InitialSyncProgress?> _readInitialProgress() async {
    try {
      return await _initialSyncService.progress.first.timeout(
        _initialProgressTimeout,
      );
    } on TimeoutException {
      return null;
    }
  }

  Future<bool?> _hasLocalDataWithTimeout([String? startupId]) async {
    try {
      final results = await Future.wait<dynamic>([
        _sharedDataService.watchAllTaskCount().first.timeout(
          _localProbeTimeout,
        ),
        _sharedDataService.watchValues().first.timeout(_localProbeTimeout),
      ]);

      final taskCount = results[0] as int;
      final values = results[1] as List<Value>;
      return taskCount > 0 || values.isNotEmpty;
    } catch (error, stackTrace) {
      final fields = <String, Object?>{
        ...?startupId == null
            ? null
            : <String, Object?>{'startupId': startupId},
      };
      AppLog.handleStructured(
        'startup.sync_gate',
        'local data probe failed',
        error,
        stackTrace,
        fields,
      );
      return null;
    }
  }
}
