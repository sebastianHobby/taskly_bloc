part of '../../forms/field_key.dart';

/// Stable, typed field IDs for task editor forms.
abstract final class TaskFieldKeys {
  static const name = FieldKey('task.name');
  static const description = FieldKey('task.description');
  static const completed = FieldKey('task.completed');
  static const projectId = FieldKey('task.projectId');
  static const startDate = FieldKey('task.startDate');
  static const deadlineDate = FieldKey('task.deadlineDate');
  static const repeatIcalRrule = FieldKey('task.repeatIcalRrule');
  static const priority = FieldKey('task.priority');
  static const valueIds = FieldKey('task.valueIds');
}
