import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/time/temporal_trigger_service.dart';

/// Reasons the app may request a refresh of today's allocation snapshot.
enum AllocationSnapshotRefreshReason {
  /// Allocation inputs (tasks/projects/settings) changed.
  inputsChanged,

  /// The user finished focus setup and saved allocation settings.
  focusSetupSaved,

  /// Manual/explicit request from the app.
  manual,

  /// Home-day boundary crossed (new "today").
  homeDayBoundaryCrossed,
}

/// Central coordinator for *when* allocation should run to keep today's
/// allocation snapshot generated and up-to-date.
///
/// This unifies trigger logic so UI and other flows do not call allocation
/// directly (except as a snapshot-missing fallback).
class AllocationSnapshotCoordinator {
  AllocationSnapshotCoordinator({
    required AllocationOrchestrator allocationOrchestrator,
    required TemporalTriggerService temporalTriggerService,
    this.debounceWindow = const Duration(milliseconds: 600),
  }) : _allocationOrchestrator = allocationOrchestrator,
       _temporalTriggerService = temporalTriggerService;

  final AllocationOrchestrator _allocationOrchestrator;
  final TemporalTriggerService _temporalTriggerService;
  final Duration debounceWindow;

  StreamSubscription<(List<Task>, List<Project>, AllocationConfig)>?
  _inputsSubscription;
  StreamSubscription<void>? _triggerSubscription;
  StreamSubscription<TemporalTriggerEvent>? _temporalSubscription;

  final PublishSubject<_RefreshSignal> _signals =
      PublishSubject<_RefreshSignal>();

  (List<Task>, List<Project>, AllocationConfig)? _latestInputs;

  bool _started = false;

  bool _refreshInFlight = false;
  bool _refreshPending = false;

  void start() {
    if (_started) return;
    _started = true;

    _inputsSubscription = _allocationOrchestrator.combineStreams().listen((
      combined,
    ) {
      _latestInputs = combined;
      _signals.add(const _RefreshSignal.debounced());
    });

    _temporalSubscription = _temporalTriggerService.events.listen((event) {
      if (event is HomeDayBoundaryCrossed) {
        requestRefreshNow(
          AllocationSnapshotRefreshReason.homeDayBoundaryCrossed,
        );
      }
    });

    final immediate = _signals.where((s) => s.immediate).map((_) => null);
    final debounced = _signals
        .where((s) => !s.immediate)
        .debounceTime(debounceWindow)
        .map((_) => null);

    _triggerSubscription = Rx.merge([immediate, debounced])
        .asyncMap((_) => _reconcileLatestIfApplicable())
        .listen(
          (_) {},
          onError: (Object e, StackTrace s) {
            talker.handle(
              e,
              s,
              '[AllocationSnapshotCoordinator] refresh stream error',
            );
          },
        );
  }

  /// Requests a refresh, potentially debounced.
  void requestRefresh(AllocationSnapshotRefreshReason reason) {
    _signals.add(_RefreshSignal.debounced(reason: reason));
  }

  /// Requests a refresh that runs as soon as possible (no debounce window).
  void requestRefreshNow(AllocationSnapshotRefreshReason reason) {
    _signals.add(_RefreshSignal.immediate(reason: reason));
  }

  Future<void> dispose() async {
    await _inputsSubscription?.cancel();
    await _triggerSubscription?.cancel();
    await _temporalSubscription?.cancel();
    await _signals.close();

    _inputsSubscription = null;
    _triggerSubscription = null;
    _temporalSubscription = null;
  }

  Future<void> _reconcileLatestIfApplicable() async {
    if (_refreshInFlight) {
      _refreshPending = true;
      return;
    }

    final inputs = _latestInputs;
    if (inputs == null) return;

    final tasks = inputs.$1;
    final allocationConfig = inputs.$3;

    // Only try to ensure a snapshot exists if the user has completed focus
    // setup and there is work to allocate.
    if (!allocationConfig.hasSelectedFocusMode) return;
    if (allocationConfig.dailyLimit <= 0) return;
    if (tasks.isEmpty) return;

    _refreshInFlight = true;
    try {
      await _allocationOrchestrator.watchAllocation().first;
    } catch (e, s) {
      talker.handle(e, s, '[AllocationSnapshotCoordinator] refresh failed');
    } finally {
      _refreshInFlight = false;
    }

    if (_refreshPending) {
      _refreshPending = false;
      await _reconcileLatestIfApplicable();
    }
  }
}

class _RefreshSignal {
  const _RefreshSignal._({required this.immediate, this.reason});

  const _RefreshSignal.debounced({AllocationSnapshotRefreshReason? reason})
    : this._(immediate: false, reason: reason);

  const _RefreshSignal.immediate({AllocationSnapshotRefreshReason? reason})
    : this._(immediate: true, reason: reason);

  final bool immediate;
  final AllocationSnapshotRefreshReason? reason;
}
