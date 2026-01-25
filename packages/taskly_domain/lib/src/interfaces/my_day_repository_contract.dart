import 'package:taskly_domain/src/my_day/model/my_day_day_picks.dart';
import 'package:taskly_domain/src/my_day/model/my_day_pick.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class MyDayRepositoryContract {
  /// Watch persisted day picks for a specific day.
  ///
  /// Stream contract:
  /// - broadcast: do not assume
  /// - replay: none
  /// - cold/hot: typically hot
  Stream<MyDayDayPicks> watchDay(DateTime dayKeyUtc);

  Future<MyDayDayPicks> loadDay(DateTime dayKeyUtc);

  Future<void> setDayPicks({
    required DateTime dayKeyUtc,
    required DateTime ritualCompletedAtUtc,
    required List<MyDayPick> picks,
    required OperationContext context,
  });

  Future<void> appendPick({
    required DateTime dayKeyUtc,
    required String taskId,
    required MyDayPickBucket bucket,
    required OperationContext context,
  });

  /// Drops persisted picks and ritual metadata for a specific day.
  Future<void> clearDay({
    required DateTime dayKeyUtc,
    OperationContext? context,
  });
}
