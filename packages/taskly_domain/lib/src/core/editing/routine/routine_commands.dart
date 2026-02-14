import 'package:flutter/foundation.dart';

import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/routines/model/routine_schedule_mode.dart';

@immutable
final class CreateRoutineCommand {
  const CreateRoutineCommand({
    required this.name,
    required this.projectId,
    required this.periodType,
    required this.scheduleMode,
    required this.targetCount,
    this.scheduleDays = const <int>[],
    this.scheduleMonthDays = const <int>[],
    this.scheduleTimeMinutes,
    this.minSpacingDays,
    this.restDayBuffer,
    this.isActive = true,
    this.pausedUntilUtc,
    this.checklistTitles = const <String>[],
  });

  final String name;
  final String projectId;
  final RoutinePeriodType periodType;
  final RoutineScheduleMode scheduleMode;
  final int targetCount;
  final List<int> scheduleDays;
  final List<int> scheduleMonthDays;
  final int? scheduleTimeMinutes;
  final int? minSpacingDays;
  final int? restDayBuffer;
  final bool isActive;
  final DateTime? pausedUntilUtc;
  final List<String> checklistTitles;
}

@immutable
final class UpdateRoutineCommand {
  const UpdateRoutineCommand({
    required this.id,
    required this.name,
    required this.projectId,
    required this.periodType,
    required this.scheduleMode,
    required this.targetCount,
    this.scheduleDays = const <int>[],
    this.scheduleMonthDays = const <int>[],
    this.scheduleTimeMinutes,
    this.minSpacingDays,
    this.restDayBuffer,
    this.isActive = true,
    this.pausedUntilUtc,
    this.checklistTitles = const <String>[],
  });

  final String id;
  final String name;
  final String projectId;
  final RoutinePeriodType periodType;
  final RoutineScheduleMode scheduleMode;
  final int targetCount;
  final List<int> scheduleDays;
  final List<int> scheduleMonthDays;
  final int? scheduleTimeMinutes;
  final int? minSpacingDays;
  final int? restDayBuffer;
  final bool isActive;
  final DateTime? pausedUntilUtc;
  final List<String> checklistTitles;
}
