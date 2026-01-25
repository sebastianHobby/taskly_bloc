import 'package:flutter/foundation.dart';

@immutable
class RoutineCompletion {
  const RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.completedAtUtc,
    required this.createdAtUtc,
  });

  final String id;
  final String routineId;
  final DateTime completedAtUtc;
  final DateTime createdAtUtc;
}
