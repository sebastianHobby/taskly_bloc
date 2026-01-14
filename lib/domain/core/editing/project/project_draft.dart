import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';

@immutable
final class ProjectDraft {
  const ProjectDraft({
    required this.name,
    required this.completed,
    this.description,
    this.startDate,
    this.deadlineDate,
    this.priority,
    this.repeatIcalRrule,
    this.valueIds = const <String>[],
  });

  factory ProjectDraft.empty() => const ProjectDraft(
    name: '',
    completed: false,
    description: null,
    startDate: null,
    deadlineDate: null,
    priority: null,
    repeatIcalRrule: null,
    valueIds: <String>[],
  );

  factory ProjectDraft.fromProject(Project project) => ProjectDraft(
    name: project.name,
    completed: project.completed,
    description: project.description,
    startDate: project.startDate,
    deadlineDate: project.deadlineDate,
    priority: project.priority,
    repeatIcalRrule: project.repeatIcalRrule,
    valueIds: project.values.map((v) => v.id).toList(),
  );

  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final int? priority;
  final String? repeatIcalRrule;
  final List<String> valueIds;

  ProjectDraft copyWith({
    String? name,
    bool? completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    int? priority,
    String? repeatIcalRrule,
    List<String>? valueIds,
  }) {
    return ProjectDraft(
      name: name ?? this.name,
      completed: completed ?? this.completed,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      priority: priority ?? this.priority,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      valueIds: valueIds ?? this.valueIds,
    );
  }
}
