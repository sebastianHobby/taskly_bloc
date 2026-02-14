import 'package:taskly_domain/src/routines/model/routine.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/routines/model/routine_schedule_mode.dart';

final class RoutineDraft {
  const RoutineDraft({
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

  factory RoutineDraft.empty() {
    return const RoutineDraft(
      name: '',
      projectId: '',
      periodType: RoutinePeriodType.week,
      scheduleMode: RoutineScheduleMode.flexible,
      targetCount: 3,
      checklistTitles: <String>[],
    );
  }

  factory RoutineDraft.fromRoutine(Routine routine) {
    return RoutineDraft(
      name: routine.name,
      projectId: routine.projectId,
      periodType: routine.periodType,
      scheduleMode: routine.scheduleMode,
      targetCount: routine.targetCount,
      scheduleDays: routine.scheduleDays,
      scheduleMonthDays: routine.scheduleMonthDays,
      scheduleTimeMinutes: routine.scheduleTimeMinutes,
      minSpacingDays: routine.minSpacingDays,
      restDayBuffer: routine.restDayBuffer,
      isActive: routine.isActive,
      pausedUntilUtc: routine.pausedUntil,
      checklistTitles: const <String>[],
    );
  }

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

  RoutineDraft copyWith({
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
    DateTime? pausedUntilUtc,
    List<String>? checklistTitles,
  }) {
    return RoutineDraft(
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
      pausedUntilUtc: pausedUntilUtc ?? this.pausedUntilUtc,
      checklistTitles: checklistTitles ?? this.checklistTitles,
    );
  }
}
