import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';

@immutable
final class ValueDraft {
  const ValueDraft({
    required this.name,
    required this.color,
    required this.priority,
  });

  factory ValueDraft.empty() => const ValueDraft(
    name: '',
    color: '#000000',
    priority: ValuePriority.medium,
  );

  factory ValueDraft.fromValue(Value value) => ValueDraft(
    name: value.name,
    color: value.color ?? '#000000',
    priority: value.priority,
  );

  final String name;
  final String color;
  final ValuePriority priority;

  ValueDraft copyWith({
    String? name,
    String? color,
    ValuePriority? priority,
  }) {
    return ValueDraft(
      name: name ?? this.name,
      color: color ?? this.color,
      priority: priority ?? this.priority,
    );
  }
}
