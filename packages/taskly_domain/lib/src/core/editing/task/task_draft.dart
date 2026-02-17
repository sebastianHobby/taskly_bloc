import 'package:flutter/foundation.dart';
import 'package:taskly_domain/src/core/model/task.dart';

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
    this.reminderKind = TaskReminderKind.none,
    this.reminderAtUtc,
    this.reminderMinutesBeforeDue,
    this.repeatIcalRrule,
    this.repeatFromCompletion = false,
    this.seriesEnded = false,
    this.valueIds = const <String>[],
    this.checklistTitles = const <String>[],
  });

  factory TaskDraft.empty() => const TaskDraft(
    name: '',
    completed: false,
    description: null,
    startDate: null,
    deadlineDate: null,
    projectId: null,
    priority: null,
    reminderKind: TaskReminderKind.none,
    reminderAtUtc: null,
    reminderMinutesBeforeDue: null,
    repeatIcalRrule: null,
    repeatFromCompletion: false,
    seriesEnded: false,
    valueIds: <String>[],
    checklistTitles: <String>[],
  );

  factory TaskDraft.fromTask(Task task) => TaskDraft(
    name: task.name,
    completed: task.completed,
    description: task.description,
    startDate: task.startDate,
    deadlineDate: task.deadlineDate,
    projectId: task.projectId,
    priority: task.priority,
    reminderKind: task.reminderKind,
    reminderAtUtc: task.reminderAtUtc,
    reminderMinutesBeforeDue: task.reminderMinutesBeforeDue,
    repeatIcalRrule: task.repeatIcalRrule,
    repeatFromCompletion: task.repeatFromCompletion,
    seriesEnded: task.seriesEnded,
    valueIds: task.values.map((v) => v.id).toList(),
    checklistTitles: const <String>[],
  );

  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final String? projectId;
  final int? priority;
  final TaskReminderKind reminderKind;
  final DateTime? reminderAtUtc;
  final int? reminderMinutesBeforeDue;
  final String? repeatIcalRrule;
  final bool repeatFromCompletion;
  final bool seriesEnded;
  final List<String> valueIds;
  final List<String> checklistTitles;

  TaskDraft copyWith({
    String? name,
    bool? completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    TaskReminderKind? reminderKind,
    DateTime? reminderAtUtc,
    int? reminderMinutesBeforeDue,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    List<String>? valueIds,
    List<String>? checklistTitles,
  }) {
    return TaskDraft(
      name: name ?? this.name,
      completed: completed ?? this.completed,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      projectId: projectId ?? this.projectId,
      priority: priority ?? this.priority,
      reminderKind: reminderKind ?? this.reminderKind,
      reminderAtUtc: reminderAtUtc ?? this.reminderAtUtc,
      reminderMinutesBeforeDue:
          reminderMinutesBeforeDue ?? this.reminderMinutesBeforeDue,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
      seriesEnded: seriesEnded ?? this.seriesEnded,
      valueIds: valueIds ?? this.valueIds,
      checklistTitles: checklistTitles ?? this.checklistTitles,
    );
  }
}
