import 'package:taskly_domain/routines.dart';

final class RoutineListItem {
  const RoutineListItem({
    required this.routine,
    required this.snapshot,
    required this.isCatchUpDay,
    required this.dayKeyUtc,
    required this.completionsInPeriod,
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
  final bool isCatchUpDay;
  final DateTime dayKeyUtc;
  final List<RoutineCompletion> completionsInPeriod;
}
