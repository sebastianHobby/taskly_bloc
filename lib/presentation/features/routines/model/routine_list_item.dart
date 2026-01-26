import 'package:taskly_domain/routines.dart';

final class RoutineListItem {
  const RoutineListItem({
    required this.routine,
    required this.snapshot,
    required this.isCatchUpDay,
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
  final bool isCatchUpDay;
}
