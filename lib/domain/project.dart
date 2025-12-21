import 'package:taskly_bloc/domain/value.dart';
import 'package:taskly_bloc/domain/label.dart';

class Project {
  Project({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.completed,
    this.description,
    this.startDate,
    this.deadlineDate,
    this.repeatIcalRrule,
    List<ValueModel>? values,
    List<Label>? labels,
  }) : values = values ?? <ValueModel>[],
       labels = labels ?? <Label>[];

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final String? repeatIcalRrule;
  final List<ValueModel> values;
  final List<Label> labels;
}
