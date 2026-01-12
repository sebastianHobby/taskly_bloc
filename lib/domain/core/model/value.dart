import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';

/// Domain representation of a Value used across the app.
@immutable
class Value {
  const Value({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.color,
    this.iconName,
    this.priority = ValuePriority.medium,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? color;
  final String? iconName;
  final ValuePriority priority;

  /// Creates a copy of this Value with the given fields replaced.
  Value copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? color,
    String? iconName,
    ValuePriority? priority,
  }) {
    return Value(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Value &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name &&
        other.color == color &&
        other.iconName == iconName &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    color,
    iconName,
    priority,
  );

  @override
  String toString() {
    return 'Value(id: $id, name: $name, color: $color, iconName: $iconName, priority: $priority)';
  }
}
