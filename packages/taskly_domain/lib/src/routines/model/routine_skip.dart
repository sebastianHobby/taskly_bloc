import 'package:flutter/foundation.dart';

enum RoutineSkipPeriodType { week, month }

@immutable
class RoutineSkip {
  const RoutineSkip({
    required this.id,
    required this.routineId,
    required this.periodType,
    required this.periodKeyUtc,
    required this.createdAtUtc,
  });

  final String id;
  final String routineId;
  final RoutineSkipPeriodType periodType;
  final DateTime periodKeyUtc;
  final DateTime createdAtUtc;
}
