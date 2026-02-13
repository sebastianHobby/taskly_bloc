part of '../../forms/field_key.dart';

/// Stable, typed field IDs for routine editor forms.
abstract final class RoutineFieldKeys {
  static const name = FieldKey('routine.name');
  static const projectId = FieldKey('routine.projectId');
  static const periodType = FieldKey('routine.periodType');
  static const scheduleMode = FieldKey('routine.scheduleMode');
  static const targetCount = FieldKey('routine.targetCount');
  static const scheduleDays = FieldKey('routine.scheduleDays');
  static const scheduleMonthDays = FieldKey('routine.scheduleMonthDays');
  static const scheduleTimeMinutes = FieldKey('routine.scheduleTimeMinutes');
  static const minSpacingDays = FieldKey('routine.minSpacingDays');
  static const restDayBuffer = FieldKey('routine.restDayBuffer');
  static const isActive = FieldKey('routine.isActive');
  static const pausedUntil = FieldKey('routine.pausedUntil');
}
