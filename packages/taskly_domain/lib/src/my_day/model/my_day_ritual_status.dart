import 'package:taskly_domain/src/my_day/model/my_day_day_picks.dart';
import 'package:taskly_domain/src/my_day/model/my_day_pick.dart';

final class MyDayRitualStatus {
  const MyDayRitualStatus({
    required this.dayKeyUtc,
    required this.hasAnyPick,
    required this.totalPickCount,
    required this.countsByBucket,
    required this.ritualCompletedAtUtc,
  });

  factory MyDayRitualStatus.fromDayPicks(MyDayDayPicks dayPicks) {
    final counts = <MyDayPickBucket, int>{};
    for (final pick in dayPicks.picks) {
      counts.update(pick.bucket, (v) => v + 1, ifAbsent: () => 1);
    }

    return MyDayRitualStatus(
      dayKeyUtc: dayPicks.dayKeyUtc,
      hasAnyPick: dayPicks.picks.isNotEmpty,
      totalPickCount: dayPicks.picks.length,
      countsByBucket: Map.unmodifiable(counts),
      ritualCompletedAtUtc: dayPicks.ritualCompletedAtUtc,
    );
  }

  final DateTime dayKeyUtc;
  final bool hasAnyPick;
  final int totalPickCount;
  final Map<MyDayPickBucket, int> countsByBucket;
  final DateTime? ritualCompletedAtUtc;
}
