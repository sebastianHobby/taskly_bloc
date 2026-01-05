import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Extension for Task to support value inheritance from parent projects
extension TaskValueInheritance on Task {
  /// Returns all effective values for this task, including inherited values from project.
  ///
  /// Implementation: Always-on, additive inheritance.
  /// - Task values are included directly
  /// - Project values are added if not already present on the task
  /// - Duplicates are filtered by value ID
  ///
  /// This provides a simple, predictable inheritance model:
  /// - Child tasks can add more values beyond their project
  /// - Project values automatically apply to all tasks in that project
  /// - No configuration needed - inheritance is always active
  ///
  /// Example:
  /// ```dart
  /// // Project has values: [Health, Family]
  /// // Task has values: [Work]
  /// final effectiveValues = task.getEffectiveValues();
  /// // Result: [Work, Health, Family] - all values combined
  /// ```
  List<Value> getEffectiveValues() {
    // Get task's direct values
    final taskValues = values;

    // Get project's values (if project exists)
    final projectValues = project?.values ?? <Value>[];

    // Combine: start with task values, then add project values not already present
    final combined = <Value>[...taskValues];

    for (final projectValue in projectValues) {
      // Only add project value if not already in task values
      if (!combined.any((taskValue) => taskValue.id == projectValue.id)) {
        combined.add(projectValue);
      }
    }

    return combined;
  }

  /// Returns only the values directly assigned to this task (not inherited).
  List<Value> getDirectValues() {
    return values;
  }

  /// Returns only the values inherited from the parent project.
  List<Value> getInheritedValues() {
    final taskValueIds = getDirectValues().map((v) => v.id).toSet();
    final projectValues = project?.values ?? <Value>[];

    return projectValues.where((pv) => !taskValueIds.contains(pv.id)).toList();
  }

  /// Checks if a specific value is inherited from the project.
  bool isValueInherited(String valueId) {
    return getInheritedValues().any((v) => v.id == valueId);
  }
}
