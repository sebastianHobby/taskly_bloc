import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';

@immutable
final class CreateValueCommand {
  const CreateValueCommand({
    required this.name,
    required this.color,
    required this.priority,
    this.iconName,
  });

  final String name;
  final String color;
  final ValuePriority priority;
  final String? iconName;
}

@immutable
final class UpdateValueCommand {
  const UpdateValueCommand({
    required this.id,
    required this.name,
    required this.color,
    required this.priority,
    this.iconName,
  });

  final String id;
  final String name;
  final String color;
  final ValuePriority priority;
  final String? iconName;
}
