import 'package:flutter/foundation.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/value.dart';
import 'package:taskly_domain/src/routines/model/routine_type.dart';

@immutable
class Routine {
  const Routine({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.valueId,
    required this.routineType,
    required this.targetCount,
    this.projectId,
    this.scheduleDays = const <int>[],
    this.minSpacingDays,
    this.restDayBuffer,
    this.preferredWeeks = const <int>[],
    this.fixedDayOfMonth,
    this.fixedWeekday,
    this.fixedWeekOfMonth,
    this.isActive = true,
    this.pausedUntil,
    this.value,
    this.project,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String valueId;
  final String? projectId;
  final RoutineType routineType;
  final int targetCount;

  /// Days of week for weekly_fixed routines (1=Mon, 7=Sun).
  final List<int> scheduleDays;

  /// Minimum spacing between completions (hard spacing).
  final int? minSpacingDays;

  /// Optional rest day buffer (soft spacing).
  final int? restDayBuffer;

  /// Preferred weeks for monthly_flexible routines (1-4 or 5=last week).
  final List<int> preferredWeeks;

  /// Fixed day of month for monthly_fixed routines (1-31).
  final int? fixedDayOfMonth;

  /// Fixed weekday for monthly_fixed routines (1=Mon, 7=Sun).
  final int? fixedWeekday;

  /// Fixed week of month for monthly_fixed routines (1-5).
  final int? fixedWeekOfMonth;

  final bool isActive;
  final DateTime? pausedUntil;

  final Value? value;
  final Project? project;

  bool isPausedOn(DateTime dayKeyUtc) {
    final paused = pausedUntil;
    if (paused == null) return false;
    return paused.isAfter(dayKeyUtc) || paused.isAtSameMomentAs(dayKeyUtc);
  }

  Routine copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? valueId,
    String? projectId,
    RoutineType? routineType,
    int? targetCount,
    List<int>? scheduleDays,
    int? minSpacingDays,
    int? restDayBuffer,
    List<int>? preferredWeeks,
    int? fixedDayOfMonth,
    int? fixedWeekday,
    int? fixedWeekOfMonth,
    bool? isActive,
    DateTime? pausedUntil,
    Value? value,
    Project? project,
  }) {
    return Routine(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      valueId: valueId ?? this.valueId,
      projectId: projectId ?? this.projectId,
      routineType: routineType ?? this.routineType,
      targetCount: targetCount ?? this.targetCount,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      minSpacingDays: minSpacingDays ?? this.minSpacingDays,
      restDayBuffer: restDayBuffer ?? this.restDayBuffer,
      preferredWeeks: preferredWeeks ?? this.preferredWeeks,
      fixedDayOfMonth: fixedDayOfMonth ?? this.fixedDayOfMonth,
      fixedWeekday: fixedWeekday ?? this.fixedWeekday,
      fixedWeekOfMonth: fixedWeekOfMonth ?? this.fixedWeekOfMonth,
      isActive: isActive ?? this.isActive,
      pausedUntil: pausedUntil ?? this.pausedUntil,
      value: value ?? this.value,
      project: project ?? this.project,
    );
  }
}
