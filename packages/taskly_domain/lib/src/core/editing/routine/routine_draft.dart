import 'package:taskly_domain/src/routines/model/routine.dart';
import 'package:taskly_domain/src/routines/model/routine_type.dart';

final class RoutineDraft {
  const RoutineDraft({
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

  factory RoutineDraft.empty() {
    return const RoutineDraft(
      name: '',
      valueId: '',
      routineType: RoutineType.weeklyFlexible,
      targetCount: 3,
    );
  }

  factory RoutineDraft.fromRoutine(Routine routine) {
    return RoutineDraft(
      name: routine.name,
      valueId: routine.valueId,
      routineType: routine.routineType,
      targetCount: routine.targetCount,
      scheduleDays: routine.scheduleDays,
      minSpacingDays: routine.minSpacingDays,
      restDayBuffer: routine.restDayBuffer,
      preferredWeeks: routine.preferredWeeks,
      fixedDayOfMonth: routine.fixedDayOfMonth,
      fixedWeekday: routine.fixedWeekday,
      fixedWeekOfMonth: routine.fixedWeekOfMonth,
      isActive: routine.isActive,
      pausedUntilUtc: routine.pausedUntil,
    );
  }

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

  RoutineDraft copyWith({
    String? name,
    String? valueId,
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
    DateTime? pausedUntilUtc,
  }) {
    return RoutineDraft(
      name: name ?? this.name,
      valueId: valueId ?? this.valueId,
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
      pausedUntilUtc: pausedUntilUtc ?? this.pausedUntilUtc,
    );
  }
}
