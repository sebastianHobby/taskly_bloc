import 'package:meta/meta.dart';

/// Buckets used by the My Day ritual.
///
/// These correspond to the sources the user accepts items from.
enum MyDayPickBucket {
  /// Value-led suggestions selected during the ritual.
  valueSuggestions,

  /// Routine picks selected for today.
  routine,

  /// Time-sensitive picks (deadline-driven).
  due,

  /// Time-sensitive picks (start date-driven).
  starts,

  /// Manual picks that are not in the above categories.
  manual,
}

enum MyDayPickTargetType { task, routine }

@immutable
final class MyDayPick {
  const MyDayPick({
    required this.targetType,
    required this.targetId,
    required this.bucket,
    required this.sortIndex,
    required this.pickedAtUtc,
    this.suggestionRank,
    this.qualifyingValueId,
    this.reasonCodes = const <String>[],
  });

  const MyDayPick.task({
    required String taskId,
    required this.bucket,
    required this.sortIndex,
    required this.pickedAtUtc,
    this.suggestionRank,
    this.qualifyingValueId,
    this.reasonCodes = const <String>[],
  }) : targetType = MyDayPickTargetType.task,
       targetId = taskId;

  const MyDayPick.routine({
    required String routineId,
    required this.bucket,
    required this.sortIndex,
    required this.pickedAtUtc,
    this.qualifyingValueId,
  }) : targetType = MyDayPickTargetType.routine,
       targetId = routineId,
       suggestionRank = null,
       reasonCodes = const <String>[];

  final MyDayPickTargetType targetType;
  final String targetId;
  final MyDayPickBucket bucket;

  /// Global stable ordering for the day.
  final int sortIndex;

  final DateTime pickedAtUtc;

  /// Optional rank of the underlying suggestion (if sourced from allocation).
  final int? suggestionRank;

  /// Optional value id that qualified the task (if known at pick time).
  final String? qualifyingValueId;

  /// Optional reason codes (typically allocation reason codes).
  final List<String> reasonCodes;

  String? get taskId =>
      targetType == MyDayPickTargetType.task ? targetId : null;

  String? get routineId =>
      targetType == MyDayPickTargetType.routine ? targetId : null;
}
