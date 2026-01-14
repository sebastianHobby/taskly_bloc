import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';

@immutable
final class TaskDraft {
  const TaskDraft({
    required this.name,
    required this.completed,
    this.description,
    this.startDate,
    this.deadlineDate,
    this.projectId,
    this.priority,
    this.repeatIcalRrule,
    this.valueIds = const <String>[],
  });

  factory TaskDraft.empty() => const TaskDraft(
    name: '',
    completed: false,
    description: null,
    startDate: null,
    deadlineDate: null,
    projectId: null,
    priority: null,
    repeatIcalRrule: null,
    valueIds: <String>[],
  );

  factory TaskDraft.fromTask(Task task) => TaskDraft(
    name: task.name,
    completed: task.completed,
    description: task.description,
    startDate: task.startDate,
    deadlineDate: task.deadlineDate,
    projectId: task.projectId,
    priority: task.priority,
    repeatIcalRrule: task.repeatIcalRrule,
    valueIds: task.values.map((v) => v.id).toList(),
  );

  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final String? projectId;
  final int? priority;
  final String? repeatIcalRrule;
  final List<String> valueIds;

  TaskDraft copyWith({
    String? name,
    bool? completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    List<String>? valueIds,
  }) {
    return TaskDraft(
      name: name ?? this.name,
      completed: completed ?? this.completed,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      projectId: projectId ?? this.projectId,
      priority: priority ?? this.priority,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      valueIds: valueIds ?? this.valueIds,
    );
  }
}
