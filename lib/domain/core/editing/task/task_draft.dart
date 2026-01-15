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
    this.repeatFromCompletion = false,
    this.seriesEnded = false,
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
    repeatFromCompletion: false,
    seriesEnded: false,
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
    repeatFromCompletion: task.repeatFromCompletion,
    seriesEnded: task.seriesEnded,
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
  final bool repeatFromCompletion;
  final bool seriesEnded;
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
    bool? repeatFromCompletion,
    bool? seriesEnded,
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
      repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
      seriesEnded: seriesEnded ?? this.seriesEnded,
      valueIds: valueIds ?? this.valueIds,
    );
  }
}
