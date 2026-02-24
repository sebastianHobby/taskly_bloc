import 'package:flutter/foundation.dart';

@immutable
class RoutineCompletion {
  const RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.completedAtUtc,
    required this.createdAtUtc,
    this.completedDayLocal,
    this.completedWeekdayLocal,
    this.completedTimeLocalMinutes,
    this.timezoneOffsetMinutes,
  });

  final String id;
  final String routineId;
  final DateTime completedAtUtc;
  final DateTime createdAtUtc;
  final DateTime? completedDayLocal;
  final int? completedWeekdayLocal;
  final int? completedTimeLocalMinutes;
  final int? timezoneOffsetMinutes;
}
