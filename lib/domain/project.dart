import 'package:taskly_bloc/domain/value.dart';
import 'package:taskly_bloc/domain/label.dart';

class Project {
  Project({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.completed,
    List<ValueModel>? values,
    List<Label>? labels,
  }) : values = values ?? <ValueModel>[],
       labels = labels ?? <Label>[];

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final bool completed;
  final List<ValueModel> values;
  final List<Label> labels;
}
