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
}
