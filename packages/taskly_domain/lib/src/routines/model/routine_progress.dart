enum RoutineStatus { onPace, tightWeek, catchUp, restWeek }

enum RoutineWindowPhase { thisWeek, nextWeek, laterThisMonth }

enum RoutinePeriodType { week, month }

class RoutineCadenceSnapshot {
  const RoutineCadenceSnapshot({
    required this.routineId,
    required this.periodType,
    required this.periodStartUtc,
    required this.periodEndUtc,
    required this.targetCount,
    required this.completedCount,
    required this.remainingCount,
    required this.daysLeft,
    required this.status,
    this.windowPhase,
    this.nextRecommendedDayUtc,
  });

  final String routineId;
  final RoutinePeriodType periodType;
  final DateTime periodStartUtc;
  final DateTime periodEndUtc;
  final int targetCount;
  final int completedCount;
  final int remainingCount;
  final int daysLeft;
  final RoutineStatus status;
  final RoutineWindowPhase? windowPhase;
  final DateTime? nextRecommendedDayUtc;
}
