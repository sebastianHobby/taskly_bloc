import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_domain/services.dart';

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
    required InitialSyncService initialSyncService,
  }) : _coordinator = coordinator,
       _initialSyncService = initialSyncService,
       super(const InitialSyncGateInProgress(progress: null)) {
    on<InitialSyncGateStarted>(_onStarted);
    on<InitialSyncGateRetryRequested>(_onRetryRequested);
  }

  final AuthenticatedAppServicesCoordinator _coordinator;
  final InitialSyncService _initialSyncService;

  Future<void> _onStarted(
    InitialSyncGateStarted event,
    Emitter<InitialSyncGateState> emit,
  ) async {
    await emit.forEach<InitialSyncGateState>(
      _gateStateStream(),
      onData: (state) => state,
      onError: (Object error, StackTrace stackTrace) {
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
    await _onStarted(const InitialSyncGateStarted(), emit);
  }

  Stream<InitialSyncGateState> _gateStateStream() async* {
    yield const InitialSyncGateInProgress(progress: null);

    try {
      await _coordinator.start();
    } catch (e) {
      yield InitialSyncGateFailure(
        message: 'Failed to start sync session: $e',
        progress: null,
      );
      return;
    }

    try {
      await for (final progress in _initialSyncService.progress) {
        yield InitialSyncGateInProgress(progress: progress);

        if (progress.hasSynced) {
          yield const InitialSyncGateReady();
          return;
        }
      }

      yield const InitialSyncGateReady();
    } catch (e) {
      yield InitialSyncGateFailure(
        message: 'Failed while waiting for sync: $e',
        progress: null,
      );
    }
  }
}
