import 'package:meta/meta.dart';

import 'package:taskly_domain/src/my_day/model/my_day_pick.dart';

@immutable
final class MyDayDayPicks {
  const MyDayDayPicks({
    required this.dayKeyUtc,
    required this.ritualCompletedAtUtc,
    required this.picks,
  });

  /// UTC day key (date-only) that these picks belong to.
  final DateTime dayKeyUtc;

  /// Timestamp of ritual confirmation.
  ///
  /// Null means the ritual hasn't been completed for this day yet.
  final DateTime? ritualCompletedAtUtc;

  /// All picks for the day (may include already-completed tasks).
  final List<MyDayPick> picks;

  bool get hasSelection => picks.isNotEmpty;

  Set<String> get selectedTaskIds =>
      Set.unmodifiable(picks.map((p) => p.taskId));
}
