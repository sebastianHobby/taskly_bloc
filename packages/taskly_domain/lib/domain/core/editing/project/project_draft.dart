import 'package:flutter/foundation.dart';
import '../../model/project.dart';

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
    this.repeatFromCompletion = false,
    this.seriesEnded = false,
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
    repeatFromCompletion: false,
    seriesEnded: false,
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
    repeatFromCompletion: project.repeatFromCompletion,
    seriesEnded: project.seriesEnded,
    valueIds: project.values.map((v) => v.id).toList(),
  );

  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final int? priority;
  final String? repeatIcalRrule;
  final bool repeatFromCompletion;
  final bool seriesEnded;
  final List<String> valueIds;

  ProjectDraft copyWith({
    String? name,
    bool? completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
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
      repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
      seriesEnded: seriesEnded ?? this.seriesEnded,
      valueIds: valueIds ?? this.valueIds,
    );
  }
}
