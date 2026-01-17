part of '../../forms/field_key.dart';

/// Stable, typed field IDs for project editor forms.
abstract final class ProjectFieldKeys {
  static const name = FieldKey('project.name');
  static const description = FieldKey('project.description');
  static const completed = FieldKey('project.completed');
  static const startDate = FieldKey('project.startDate');
  static const deadlineDate = FieldKey('project.deadlineDate');
  static const repeatIcalRrule = FieldKey('project.repeatIcalRrule');
  static const repeatFromCompletion = FieldKey(
    'project.repeatFromCompletion',
  );
  static const seriesEnded = FieldKey('project.seriesEnded');
  static const priority = FieldKey('project.priority');
  static const valueIds = FieldKey('project.valueIds');
}
