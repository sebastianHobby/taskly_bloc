import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Extension for Task to support value inheritance from parent projects.
///
/// **@deprecated** This extension is deprecated and will be removed in a future
/// release. Value inheritance has been removed from the architecture.
///
/// **Migration:**
/// - Use `task.values` directly instead of `getEffectiveValues()`
/// - Values are now pre-populated from project as template when creating tasks
/// - Once saved, task values are independent of project values
///
/// See: BACKEND_MIGRATION_PLAN.md Change #10
@Deprecated('Use task.values directly. Value inheritance has been removed.')
extension TaskValueInheritance on Task {
  /// Returns all effective values for this task.
  ///
  /// **@deprecated** Use `task.values` directly instead.
  ///
  /// Previously included inherited values from project. Now returns the same
  /// as `task.values` for backward compatibility.
  @Deprecated('Use task.values directly. Value inheritance has been removed.')
  List<Value> getEffectiveValues() {
    // Value inheritance removed - return direct values only
    return values;
  }

  /// Returns only the values directly assigned to this task (not inherited).
  ///
  /// **@deprecated** Use `task.values` directly instead.
  @Deprecated('Use task.values directly. Value inheritance has been removed.')
  List<Value> getDirectValues() {
    return values;
  }

  /// Returns only the values inherited from the parent project.
  ///
  /// **@deprecated** Value inheritance has been removed.
  /// Always returns an empty list for backward compatibility.
  @Deprecated('Value inheritance has been removed. Returns empty list.')
  List<Value> getInheritedValues() {
    // Value inheritance removed - return empty list
    return const <Value>[];
  }

  /// Checks if a specific value is inherited from the project.
  ///
  /// **@deprecated** Value inheritance has been removed.
  /// Always returns false for backward compatibility.
  @Deprecated('Value inheritance has been removed. Always returns false.')
  bool isValueInherited(String valueId) {
    // Value inheritance removed - nothing is inherited
    return false;
  }
}
