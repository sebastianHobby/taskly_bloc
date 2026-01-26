import 'package:taskly_domain/routines.dart';

final class RoutineListItem {
  const RoutineListItem({
    required this.routine,
    required this.snapshot,
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
}
