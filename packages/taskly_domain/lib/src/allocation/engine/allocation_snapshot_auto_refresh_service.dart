import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/allocation/model/allocation_config.dart';
import 'package:taskly_domain/src/allocation/engine/allocation_orchestrator.dart';

/// Debounced, best-effort refresher for today's allocation snapshot.
///
/// This exists to support a snapshot-first UX (stable My Day) while still
/// allowing snapshot membership to shrink (completed tasks) and, when the day
/// was generated with a shortage, to top up remaining slots.
///
/// Important behavior:
/// - Runs in the background once started.
/// - On app start (initial stream emission), it can generate today's snapshot
///   when allocation is eligible.
/// - On subsequent input changes, it triggers a debounced recompute/persist
///   pass. The allocator's stabilization rules prevent reshuffles.
class AllocationSnapshotAutoRefreshService {
  AllocationSnapshotAutoRefreshService({
    required AllocationOrchestrator allocationOrchestrator,
    this.debounceWindow = const Duration(milliseconds: 600),
  }) : _allocationOrchestrator = allocationOrchestrator;

  final AllocationOrchestrator _allocationOrchestrator;
  final Duration debounceWindow;

  StreamSubscription<void>? _subscription;
  bool _started = false;

  bool _refreshInFlight = false;
  bool _refreshPending = false;

  void start() {
    if (_started) return;
    _started = true;

    _subscription = _allocationOrchestrator
        .combineStreams()
        .debounceTime(debounceWindow)
        .asyncMap(_reconcileIfApplicable)
        .listen(
          (_) {},
          onError: (Object e, StackTrace s) {
            talker.handle(
              e,
              s,
              '[AllocationSnapshotAutoRefreshService] refresh stream error',
            );
          },
        );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _reconcileIfApplicable(
    (List<dynamic>, List<dynamic>, AllocationConfig) combined,
  ) async {
    if (_refreshInFlight) {
      _refreshPending = true;
      return;
    }

    final tasks = combined.$1;
    final allocationConfig = combined.$3;

    // Policy A: only try to ensure a snapshot exists if the user has completed
    // focus setup and there is work to allocate.
    if (!allocationConfig.hasSelectedFocusMode) return;
    if (allocationConfig.dailyLimit <= 0) return;
    if (tasks.isEmpty) return;

    _refreshInFlight = true;
    try {
      await _allocationOrchestrator.watchAllocation().first;
    } catch (e, s) {
      talker.handle(
        e,
        s,
        '[AllocationSnapshotAutoRefreshService] refresh failed',
      );
    } finally {
      _refreshInFlight = false;
    }

    if (_refreshPending) {
      _refreshPending = false;
      await _reconcileIfApplicable(combined);
    }
  }
}
