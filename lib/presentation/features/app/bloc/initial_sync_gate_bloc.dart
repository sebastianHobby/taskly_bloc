import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
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
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
  }) : _coordinator = coordinator,
       _initialSyncService = initialSyncService,
       _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       super(const InitialSyncGateInProgress(progress: null)) {
    on<InitialSyncGateStarted>(_onStarted);
    on<InitialSyncGateRetryRequested>(_onRetryRequested);
  }

  final AuthenticatedAppServicesCoordinator _coordinator;
  final InitialSyncService _initialSyncService;
  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;

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
      _taskRepository.watchAllCount().first,
      _valueRepository.getAll(),
    ]);

    final taskCount = results[0] as int;
    final values = results[1] as List<Value>;
    final hasLocalData = taskCount > 0 || values.isNotEmpty;

    return !hasLocalData;
  }
}
