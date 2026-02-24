import 'package:flutter/foundation.dart';

enum MyDayDecisionEntityType { task, routine }

enum MyDayDecisionShelf {
  due,
  planned,
  routineScheduled,
  routineFlexible,
  suggestion,
}

enum MyDayDecisionAction { kept, deferred, snoozed, removed, completed }

enum MyDayDecisionDeferKind {
  deadlineReschedule,
  startReschedule,
  snooze,
}

@immutable
final class MyDayDecisionEvent {
  const MyDayDecisionEvent({
    required this.id,
    required this.dayKeyUtc,
    required this.entityType,
    required this.entityId,
    required this.shelf,
    required this.action,
    required this.actionAtUtc,
    this.deferKind,
    this.fromDayKey,
    this.toDayKey,
    this.suggestionRank,
    this.meta,
  });

  final String id;
  final DateTime dayKeyUtc;
  final MyDayDecisionEntityType entityType;
  final String entityId;
  final MyDayDecisionShelf shelf;
  final MyDayDecisionAction action;
  final DateTime actionAtUtc;
  final MyDayDecisionDeferKind? deferKind;
  final DateTime? fromDayKey;
  final DateTime? toDayKey;
  final int? suggestionRank;
  final Map<String, Object?>? meta;
}

@immutable
final class MyDayShelfRate {
  const MyDayShelfRate({
    required this.shelf,
    required this.numerator,
    required this.denominator,
  });

  final MyDayDecisionShelf shelf;
  final int numerator;
  final int denominator;

  double get rate => denominator == 0 ? 0 : numerator / denominator;
}

@immutable
final class MyDayEntityDeferCount {
  const MyDayEntityDeferCount({
    required this.entityType,
    required this.entityId,
    required this.deferCount,
    required this.snoozeCount,
  });

  final MyDayDecisionEntityType entityType;
  final String entityId;
  final int deferCount;
  final int snoozeCount;
}

@immutable
final class RoutineWeekdayStat {
  const RoutineWeekdayStat({
    required this.routineId,
    required this.weekdayLocal,
    required this.count,
  });

  final String routineId;
  final int weekdayLocal;
  final int count;
}

@immutable
final class DeferredThenCompletedLagMetric {
  const DeferredThenCompletedLagMetric({
    required this.entityType,
    required this.entityId,
    required this.sampleSize,
    required this.medianLagHours,
    required this.p75LagHours,
    required this.completedWithin7DaysRate,
  });

  final MyDayDecisionEntityType entityType;
  final String entityId;
  final int sampleSize;
  final double medianLagHours;
  final double p75LagHours;
  final double completedWithin7DaysRate;
}
