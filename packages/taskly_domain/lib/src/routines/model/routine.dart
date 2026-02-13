import 'package:flutter/foundation.dart';
import 'package:taskly_domain/src/core/model/value.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/routines/model/routine_schedule_mode.dart';

@immutable
class Routine {
  const Routine({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
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
    this.pausedUntil,
    this.value,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String projectId;
  final RoutinePeriodType periodType;
  final RoutineScheduleMode scheduleMode;
  final int targetCount;

  /// Days of week for weekly scheduled routines (1=Mon, 7=Sun).
  final List<int> scheduleDays;

  /// Days of month for monthly scheduled routines (1-31).
  final List<int> scheduleMonthDays;

  /// Preferred time of day in minutes since midnight.
  final int? scheduleTimeMinutes;

  /// Minimum spacing between completions (hard spacing).
  final int? minSpacingDays;

  /// Optional rest day buffer (soft spacing).
  final int? restDayBuffer;

  final bool isActive;
  final DateTime? pausedUntil;

  final Value? value;

  bool isPausedOn(DateTime dayKeyUtc) {
    final paused = pausedUntil;
    if (paused == null) return false;
    return paused.isAfter(dayKeyUtc);
  }

  Routine copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? projectId,
    RoutinePeriodType? periodType,
    RoutineScheduleMode? scheduleMode,
    int? targetCount,
    List<int>? scheduleDays,
    List<int>? scheduleMonthDays,
    int? scheduleTimeMinutes,
    int? minSpacingDays,
    int? restDayBuffer,
    bool? isActive,
    DateTime? pausedUntil,
    Value? value,
  }) {
    return Routine(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      periodType: periodType ?? this.periodType,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      targetCount: targetCount ?? this.targetCount,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      scheduleMonthDays: scheduleMonthDays ?? this.scheduleMonthDays,
      scheduleTimeMinutes: scheduleTimeMinutes ?? this.scheduleTimeMinutes,
      minSpacingDays: minSpacingDays ?? this.minSpacingDays,
      restDayBuffer: restDayBuffer ?? this.restDayBuffer,
      isActive: isActive ?? this.isActive,
      pausedUntil: pausedUntil ?? this.pausedUntil,
      value: value ?? this.value,
    );
  }
}
