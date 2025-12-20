import 'package:taskly_bloc/core/domain/label.dart';
import 'package:taskly_bloc/core/domain/project.dart';
import 'package:taskly_bloc/core/domain/value.dart';

/// Domain representation of a Task used across the app.
class Task {
  Task({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.completed,
    this.startDate,
    this.deadlineDate,
    this.description,
    this.projectId,
    this.repeatIcalRrule,
    this.project,
    List<ValueModel>? values,
    List<Label>? labels,
  }) : values = values ?? <ValueModel>[],
       labels = labels ?? <Label>[];

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final bool completed;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final String? description;
  final String? projectId;
  final String? repeatIcalRrule;
  final Project? project;
  final List<ValueModel> values;
  final List<Label> labels;
}
