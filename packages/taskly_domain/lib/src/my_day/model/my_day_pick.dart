import 'package:meta/meta.dart';

/// Buckets used by the My Day ritual.
///
/// These correspond to the sections the user accepts tasks from.
enum MyDayPickBucket {
  /// A normal planned pick (selected in the ritual but not classified as due or
  /// starts, and not a curated suggestion).
  planned,

  due,
  starts,
  focus,
}

@immutable
final class MyDayPick {
  const MyDayPick({
    required this.taskId,
    required this.bucket,
    required this.sortIndex,
    required this.pickedAtUtc,
    this.suggestionRank,
    this.qualifyingValueId,
    this.reasonCodes = const <String>[],
  });

  final String taskId;
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
}
