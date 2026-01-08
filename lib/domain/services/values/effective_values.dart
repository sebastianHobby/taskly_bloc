import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/value.dart';

/// Helpers for computing a task's effective values.
///
/// Effective values follow this precedence:
/// - Task values (explicit override) if present
/// - Else project values (inherit) if present
/// - Else empty
extension TaskEffectiveValuesX on Task {
  /// The values that should be treated as active for this task.
  List<Value> get effectiveValues {
    if (values.isNotEmpty) return values;
    return project?.values ?? const <Value>[];
  }

  /// True when this task is inheriting values from its project.
  ///
  /// This is the case when the task has no explicit values but its project
  /// has values.
  bool get isInheritingValues =>
      values.isEmpty && (project?.values.isNotEmpty ?? false);

  /// The primary value id to treat as effective for this task.
  ///
  /// Task-level primary overrides project-level primary.
  String? get effectivePrimaryValueId {
    return primaryValueId ?? project?.primaryValueId;
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
    final id = effectivePrimaryValueId;
    if (id == null) return effectiveValues;
    return effectiveValues.where((v) => v.id != id).toList();
  }

  /// True when this task has no effective values.
  bool get isEffectivelyValueless => effectiveValues.isEmpty;
}
