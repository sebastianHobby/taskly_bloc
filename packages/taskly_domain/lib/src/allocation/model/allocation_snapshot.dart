/// Allocation snapshot domain models.
///
/// These represent the persisted daily allocation membership (allocated-only).
library;

/// Entity type stored in allocation snapshot entries.
enum AllocationSnapshotEntityType {
  task,
  project,
}

/// Stable reference to an allocated entity.
class AllocationEntityRef {
  const AllocationEntityRef({
    required this.type,
    required this.id,
  });

  final AllocationSnapshotEntityType type;
  final String id;

  @override
  bool operator ==(Object other) {
    return other is AllocationEntityRef && other.type == type && other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);
}

/// Entry input used when persisting a snapshot.
class AllocationSnapshotEntryInput {
  const AllocationSnapshotEntryInput({
    required this.entity,
    this.projectId,
    this.qualifyingValueId,
    this.effectivePrimaryValueId,
    this.allocationScore,
  });

  final AllocationEntityRef entity;

  /// For task entries, the owning project id (if any).
  final String? projectId;

  final String? qualifyingValueId;

  /// For task entries, the effective primary value id.
  ///
  /// Task-level primary overrides project-level primary.
  final String? effectivePrimaryValueId;
  final double? allocationScore;
}

/// A persisted snapshot for a single UTC day.
class AllocationSnapshot {
  const AllocationSnapshot({
    required this.id,
    required this.dayUtc,
    required this.version,
    required this.capAtGeneration,
    required this.candidatePoolCountAtGeneration,
    required this.allocated,
  });

  final String id;
  final DateTime dayUtc;
  final int version;
  final int capAtGeneration;
  final int candidatePoolCountAtGeneration;
  final List<AllocationSnapshotEntryInput> allocated;
}

/// A stable, ordered reference to an allocated task in a snapshot.
///
/// This is intentionally lightweight (IDs + ordering/grouping hints) and is
/// meant to be batch-hydrated via repositories (e.g. TaskRepository).
class AllocationSnapshotTaskRef {
  const AllocationSnapshotTaskRef({
    required this.taskId,
    required this.allocationRank,
    this.projectId,
    this.qualifyingValueId,
    this.effectivePrimaryValueId,
    this.allocationScore,
  });

  final String taskId;

  /// Stable ordering for allocated tasks (lower rank = earlier).
  final int allocationRank;

  /// Owning project id at allocation time (if any).
  final String? projectId;

  /// The value that qualified the task for allocation (if any).
  final String? qualifyingValueId;

  /// The effective primary value id at allocation time (if any).
  final String? effectivePrimaryValueId;

  final double? allocationScore;
}
