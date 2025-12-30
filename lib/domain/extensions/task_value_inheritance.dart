import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Extension for Task to support value inheritance from parent projects
extension TaskValueInheritance on Task {
  /// Returns all effective values for this task, including inherited values from project.
  ///
  /// Implementation: Always-on, additive inheritance.
  /// - Task values are included directly
  /// - Project values are added if not already present on the task
  /// - Duplicates are filtered by label ID
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
  List<Label> getEffectiveValues() {
    // Get task's direct values
    final taskValues = labels.where((l) => l.type == LabelType.value).toList();

    // Get project's values (if project exists)
    final projectValues =
        project?.labels.where((l) => l.type == LabelType.value).toList() ??
        <Label>[];

    // Combine: start with task values, then add project values not already present
    final combined = <Label>[...taskValues];

    for (final projectValue in projectValues) {
      // Only add project value if not already in task values
      if (!combined.any((taskValue) => taskValue.id == projectValue.id)) {
        combined.add(projectValue);
      }
    }

    return combined;
  }

  /// Returns only the values directly assigned to this task (not inherited).
  List<Label> getDirectValues() {
    return labels.where((l) => l.type == LabelType.value).toList();
  }

  /// Returns only the values inherited from the parent project.
  List<Label> getInheritedValues() {
    final taskValueIds = getDirectValues().map((l) => l.id).toSet();
    final projectValues =
        project?.labels.where((l) => l.type == LabelType.value).toList() ??
        <Label>[];

    return projectValues.where((pv) => !taskValueIds.contains(pv.id)).toList();
  }

  /// Checks if a specific value is inherited from the project.
  bool isValueInherited(String labelId) {
    return getInheritedValues().any((l) => l.id == labelId);
  }
}
