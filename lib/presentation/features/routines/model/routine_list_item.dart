import 'package:taskly_domain/routines.dart';

final class RoutineListItem {
  const RoutineListItem({
    required this.routine,
    required this.snapshot,
    required this.dayKeyUtc,
    required this.completionsInPeriod,
    required this.skipsInPeriod,
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
  final DateTime dayKeyUtc;
  final List<RoutineCompletion> completionsInPeriod;
  final List<RoutineSkip> skipsInPeriod;
}
