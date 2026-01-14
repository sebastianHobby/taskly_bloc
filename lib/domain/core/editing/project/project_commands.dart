import 'package:flutter/foundation.dart';

@immutable
final class CreateProjectCommand {
  const CreateProjectCommand({
    required this.name,
    required this.completed,
    this.description,
    this.startDate,
    this.deadlineDate,
    this.priority,
    this.repeatIcalRrule,
    this.valueIds,
  });

  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final int? priority;
  final String? repeatIcalRrule;
  final List<String>? valueIds;
}

@immutable
final class UpdateProjectCommand {
  const UpdateProjectCommand({
    required this.id,
    required this.name,
    required this.completed,
    this.description,
    this.startDate,
    this.deadlineDate,
    this.priority,
    this.repeatIcalRrule,
    this.valueIds,
  });

  final String id;
  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final int? priority;
  final String? repeatIcalRrule;
  final List<String>? valueIds;
}
