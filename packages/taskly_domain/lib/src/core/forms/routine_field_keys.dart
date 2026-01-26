part of '../../forms/field_key.dart';

/// Stable, typed field IDs for routine editor forms.
abstract final class RoutineFieldKeys {
  static const name = FieldKey('routine.name');
  static const valueId = FieldKey('routine.valueId');
  static const projectId = FieldKey('routine.projectId');
  static const routineType = FieldKey('routine.type');
  static const targetCount = FieldKey('routine.targetCount');
  static const scheduleDays = FieldKey('routine.scheduleDays');
  static const minSpacingDays = FieldKey('routine.minSpacingDays');
  static const restDayBuffer = FieldKey('routine.restDayBuffer');
  static const preferredWeeks = FieldKey('routine.preferredWeeks');
  static const fixedDayOfMonth = FieldKey('routine.fixedDayOfMonth');
  static const fixedWeekday = FieldKey('routine.fixedWeekday');
  static const fixedWeekOfMonth = FieldKey('routine.fixedWeekOfMonth');
  static const isActive = FieldKey('routine.isActive');
  static const pausedUntil = FieldKey('routine.pausedUntil');
}
