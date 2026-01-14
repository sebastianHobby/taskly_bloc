import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_project_history_window.dart';

/// Repository contract for persisted allocation snapshots.
///
/// IMPORTANT: The app must not rely on `user_id` filtering; Supabase RLS and
/// PowerSync bucket rules handle scoping.
abstract class AllocationSnapshotRepositoryContract {
  /// Returns the latest snapshot for the given UTC day.
  Future<AllocationSnapshot?> getLatestForUtcDay(DateTime dayUtc);

  /// Watches the latest snapshot for the given UTC day.
  Stream<AllocationSnapshot?> watchLatestForUtcDay(DateTime dayUtc);

  /// Returns ordered allocated task refs for the latest snapshot of [dayUtc].
  ///
  /// This is a lightweight alternative to hydrating full [Task] objects.
  Future<List<AllocationSnapshotTaskRef>> getLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  );

  /// Watches ordered allocated task refs for the latest snapshot of [dayUtc].
  Stream<List<AllocationSnapshotTaskRef>> watchLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  );

  /// Persists the allocation membership for [dayUtc].
  ///
  /// Creates a new version only when membership changes.
  Future<void> persistAllocatedForUtcDay({
    required DateTime dayUtc,
    required int capAtGeneration,
    required int candidatePoolCountAtGeneration,
    required List<AllocationSnapshotEntryInput> allocated,
  });

  /// Returns allocation history summaries for a rolling UTC day window.
  ///
  /// The returned window is inclusive on both ends.
  Future<AllocationProjectHistoryWindow> getProjectHistoryWindow({
    required DateTime windowEndDayUtc,
    required int windowDays,
  });

  /// Deletes all persisted allocation snapshots and entries.
  ///
  /// Intended for debug/reset flows (e.g. template data seeding) where the
  /// app should recompute today's allocation immediately.
  Future<void> deleteAll();
}
