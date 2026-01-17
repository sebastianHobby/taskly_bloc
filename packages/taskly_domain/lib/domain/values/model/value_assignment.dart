import 'package:flutter/foundation.dart';
import '../../core/model/value.dart';

/// Represents a value assignment to a task or project, including primary status.
///
/// Taskly's current data model uses primary/secondary value slots (and task
/// overrides). This type remains useful as a UI/domain representation of a
/// value selection with a primary flag.
@immutable
class ValueAssignment {
  const ValueAssignment({
    required this.value,
    this.isPrimary = false,
  });

  /// The assigned value.
  final Value value;

  /// Whether this is the primary value for the task/project.
  ///
  /// Only one value can be primary per entity. The primary value is used
  /// for grouping in My Day view and determines the main color/category.
  final bool isPrimary;

  /// Convenience getter for the value's ID.
  String get id => value.id;

  /// Convenience getter for the value's name.
  String get name => value.name;

  /// Convenience getter for the value's color.
  String? get color => value.color;

  /// Creates a copy of this ValueAssignment with the given fields replaced.
  ValueAssignment copyWith({
    Value? value,
    bool? isPrimary,
  }) {
    return ValueAssignment(
      value: value ?? this.value,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValueAssignment &&
        other.value == value &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(value, isPrimary);

  @override
  String toString() {
    return 'ValueAssignment(value: ${value.name}, isPrimary: $isPrimary)';
  }
}
