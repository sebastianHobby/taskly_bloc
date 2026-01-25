import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/value.dart';

/// Helpers for computing a task's effective values.
///
/// Effective values follow this behavior:
/// - Project primary value is always the primary when present.
/// - Task override values are treated as optional secondary tags.
/// - Tasks without a project have no effective values.
extension TaskEffectiveValuesX on Task {
  /// True when the task has explicit tag values.
  bool get isOverridingValues =>
      overridePrimaryValueId != null || overrideSecondaryValueId != null;

  /// The values that should be treated as active for this task.
  List<Value> get effectiveValues {
    final primaryId = effectivePrimaryValueId;
    final secondaryIds = _effectiveSecondaryValueIds;
    if (primaryId == null && secondaryIds.isEmpty) {
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

    for (final secondaryId in secondaryIds) {
      if (secondaryId == primaryId) continue;
      final secondary = candidates[secondaryId];
      if (secondary != null) result.add(secondary);
    }

    return result;
  }

  /// True when this task is inheriting values from its project.
  ///
  /// This is the case when the project provides any value slot.
  bool get isInheritingValues {
    return project?.primaryValueId != null;
  }

  /// The primary value id to treat as effective for this task.
  ///
  /// Primary value is always inherited from the project.
  String? get effectivePrimaryValueId {
    return project?.primaryValueId;
  }

  /// The secondary value id to treat as effective for this task.
  ///
  /// Returns the first effective secondary value id, if any.
  String? get effectiveSecondaryValueId {
    final ids = _effectiveSecondaryValueIds;
    return ids.isEmpty ? null : ids.first;
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
    if (_effectiveSecondaryValueIds.isEmpty) return const <Value>[];
    return effectiveValues.skip(1).toList(growable: false);
  }

  /// True when this task has no effective values.
  bool get isEffectivelyValueless => effectiveValues.isEmpty;

  List<String> get _effectiveSecondaryValueIds {
    final primaryId = effectivePrimaryValueId;
    if (primaryId == null) return const <String>[];

    final ids = <String>[];
    void addId(String? id) {
      final normalized = id?.trim();
      if (normalized == null || normalized.isEmpty) return;
      if (normalized == primaryId || ids.contains(normalized)) return;
      ids.add(normalized);
    }

    addId(overridePrimaryValueId);
    addId(overrideSecondaryValueId);

    return ids;
  }
}
