part of '../../forms/field_key.dart';

/// Stable, typed field IDs for task editor forms.
abstract final class TaskFieldKeys {
  static const name = FieldKey('task.name');
  static const description = FieldKey('task.description');
  static const completed = FieldKey('task.completed');
  static const projectId = FieldKey('task.projectId');
  static const startDate = FieldKey('task.startDate');
  static const deadlineDate = FieldKey('task.deadlineDate');
  static const reminderKind = FieldKey('task.reminderKind');
  static const reminderAtUtc = FieldKey('task.reminderAtUtc');
  static const reminderMinutesBeforeDue = FieldKey(
    'task.reminderMinutesBeforeDue',
  );
  static const repeatIcalRrule = FieldKey('task.repeatIcalRrule');
  static const repeatFromCompletion = FieldKey('task.repeatFromCompletion');
  static const seriesEnded = FieldKey('task.seriesEnded');
  static const priority = FieldKey('task.priority');
  static const valueIds = FieldKey('task.valueIds');
}
