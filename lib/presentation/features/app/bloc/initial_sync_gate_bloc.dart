import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
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
    required InitialSyncService initialSyncService,
    required SessionSharedDataService sharedDataService,
  }) : _coordinator = coordinator,
       _initialSyncService = initialSyncService,
       _sharedDataService = sharedDataService,
       super(const InitialSyncGateInProgress(progress: null)) {
    on<InitialSyncGateStarted>(_onStarted, transformer: restartable());
    on<InitialSyncGateRetryRequested>(_onRetryRequested);
  }

  final AuthenticatedAppServicesCoordinator _coordinator;
  final InitialSyncService _initialSyncService;
  final SessionSharedDataService _sharedDataService;

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
      final initial = await _initialSyncService.progress.first;
      final shouldBlock = await _shouldBlock(initial);
      if (!shouldBlock) {
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
    } catch (e) {
      yield InitialSyncGateFailure(
        message: 'Failed while waiting for sync: $e',
        progress: null,
      );
    }
  }

  Future<bool> _shouldBlock(InitialSyncProgress progress) async {
    final hasCheckpoint = progress.hasSynced || progress.lastSyncedAt != null;
    if (hasCheckpoint) return false;

    final results = await Future.wait<dynamic>([
      _sharedDataService.watchAllTaskCount().first,
      _sharedDataService.watchValues().first,
    ]);

    final taskCount = results[0] as int;
    final values = results[1] as List<Value>;
    final hasLocalData = taskCount > 0 || values.isNotEmpty;

    return !hasLocalData;
  }
}
