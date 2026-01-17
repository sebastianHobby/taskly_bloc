import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/value.dart';

/// Helpers for computing a task's effective values.
///
/// Effective values follow this precedence:
/// - Task values (explicit override) if present
/// - Else project values (inherit) if present
/// - Else empty
extension TaskEffectiveValuesX on Task {
  bool get isOverridingValues => overridePrimaryValueId != null;

  /// The values that should be treated as active for this task.
  List<Value> get effectiveValues {
    final primaryId = effectivePrimaryValueId;
    final secondaryId = effectiveSecondaryValueId;
    if (primaryId == null && secondaryId == null) {
      return const <Value>[];
    }

    // Candidates may be hydrated on the task, project, or both.
    final candidates = <String, Value>{
      for (final v in values) v.id: v,
      for (final v in project?.values ?? const <Value>[]) v.id: v,
    };

    final result = <Value>[];
    final primary = primaryId == null ? null : candidates[primaryId];
    if (primary != null) result.add(primary);

    final secondary = (secondaryId == null || secondaryId == primaryId)
        ? null
        : candidates[secondaryId];
    if (secondary != null) result.add(secondary);

    return result;
  }

  /// True when this task is inheriting values from its project.
  ///
  /// This is the case when the task has no explicit values but its project
  /// has values.
  bool get isInheritingValues {
    if (isOverridingValues) return false;
    return (project?.primaryValueId != null) ||
        (project?.secondaryValueId != null);
  }

  /// The primary value id to treat as effective for this task.
  ///
  /// Primary value inheritance follows the same override rules as values:
  /// - If the task is overriding, primary is task-only (no project fallback).
  /// - Otherwise primary is inherited from the project.
  String? get effectivePrimaryValueId {
    if (overridePrimaryValueId != null) return overridePrimaryValueId;
    return project?.primaryValueId;
  }

  /// The secondary value id to treat as effective for this task.
  ///
  /// Secondary inheritance follows the same override rule:
  /// - If overriding primary, no secondary is inherited.
  /// - Otherwise secondary is inherited from the project.
  String? get effectiveSecondaryValueId {
    if (overridePrimaryValueId != null) return overrideSecondaryValueId;
    return project?.secondaryValueId;
  }

  /// The primary value that should be displayed/used for this task.
  Value? get effectivePrimaryValue {
    final id = effectivePrimaryValueId;
    if (id == null) return null;
    return effectiveValues.cast<Value?>().firstWhere(
      (v) => v?.id == id,
      orElse: () => null,
    );
  }

  /// The secondary values that should be displayed/used for this task.
  List<Value> get effectiveSecondaryValues {
    final secondaryId = effectiveSecondaryValueId;
    if (secondaryId == null) return const <Value>[];
    final secondary = effectiveValues.cast<Value?>().firstWhere(
      (v) => v?.id == secondaryId,
      orElse: () => null,
    );
    return secondary == null ? const <Value>[] : <Value>[secondary];
  }

  /// True when this task has no effective values.
  bool get isEffectivelyValueless => effectiveValues.isEmpty;
}
