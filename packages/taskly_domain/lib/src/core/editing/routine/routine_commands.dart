import 'package:flutter/foundation.dart';

import 'package:taskly_domain/src/routines/model/routine_type.dart';

@immutable
final class CreateRoutineCommand {
  const CreateRoutineCommand({
    required this.name,
    required this.valueId,
    required this.routineType,
    required this.targetCount,
    this.scheduleDays = const <int>[],
    this.minSpacingDays,
    this.restDayBuffer,
    this.preferredWeeks = const <int>[],
    this.fixedDayOfMonth,
    this.fixedWeekday,
    this.fixedWeekOfMonth,
    this.isActive = true,
    this.pausedUntilUtc,
  });

  final String name;
  final String valueId;
  final RoutineType routineType;
  final int targetCount;
  final List<int> scheduleDays;
  final int? minSpacingDays;
  final int? restDayBuffer;
  final List<int> preferredWeeks;
  final int? fixedDayOfMonth;
  final int? fixedWeekday;
  final int? fixedWeekOfMonth;
  final bool isActive;
  final DateTime? pausedUntilUtc;
}

@immutable
final class UpdateRoutineCommand {
  const UpdateRoutineCommand({
    required this.id,
    required this.name,
    required this.valueId,
    required this.routineType,
    required this.targetCount,
    this.scheduleDays = const <int>[],
    this.minSpacingDays,
    this.restDayBuffer,
    this.preferredWeeks = const <int>[],
    this.fixedDayOfMonth,
    this.fixedWeekday,
    this.fixedWeekOfMonth,
    this.isActive = true,
    this.pausedUntilUtc,
  });

  final String id;
  final String name;
  final String valueId;
  final RoutineType routineType;
  final int targetCount;
  final List<int> scheduleDays;
  final int? minSpacingDays;
  final int? restDayBuffer;
  final List<int> preferredWeeks;
  final int? fixedDayOfMonth;
  final int? fixedWeekday;
  final int? fixedWeekOfMonth;
  final bool isActive;
  final DateTime? pausedUntilUtc;
}
