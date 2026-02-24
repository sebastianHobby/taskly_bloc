import 'package:taskly_domain/src/analytics/model/date_range.dart';
import 'package:taskly_domain/src/my_day/model/my_day_decision_event.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class MyDayDecisionEventRepositoryContract {
  Future<void> append(
    MyDayDecisionEvent event, {
    OperationContext? context,
  });

  Future<void> appendAll(
    List<MyDayDecisionEvent> events, {
    OperationContext? context,
  });

  Future<List<MyDayShelfRate>> getKeepRateByShelf({
    required DateRange range,
  });

  Future<List<MyDayShelfRate>> getDeferRateByShelf({
    required DateRange range,
  });

  Future<List<MyDayEntityDeferCount>> getEntityDeferCounts({
    required DateRange range,
    required MyDayDecisionEntityType entityType,
    int limit = 50,
  });

  Future<List<RoutineWeekdayStat>> getRoutineTopCompletionWeekdays({
    required DateRange range,
    int topPerRoutine = 2,
    int limitRoutines = 50,
  });

  Future<List<DeferredThenCompletedLagMetric>> getDeferredThenCompletedLag({
    required DateRange range,
    int limit = 50,
  });
}
