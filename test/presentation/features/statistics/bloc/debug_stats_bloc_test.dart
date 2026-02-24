@Tags(['unit', 'statistics'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/statistics/bloc/debug_stats_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart';

import '../../../../helpers/test_imports.dart';

class _MockRepo extends Mock implements MyDayDecisionEventRepositoryContract {}

class _MockNowService extends Mock implements NowService {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUpAll(() {
    registerFallbackValue(
      DateRange(start: DateTime.utc(2026, 1, 1), end: DateTime.utc(2026, 1, 2)),
    );
    registerFallbackValue(MyDayDecisionEntityType.task);
  });
  setUp(setUpTestEnvironment);

  late _MockRepo repository;
  late _MockNowService nowService;

  setUp(() {
    repository = _MockRepo();
    nowService = _MockNowService();

    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2026, 2, 24));
    when(
      () => repository.getKeepRateByShelf(range: any(named: 'range')),
    ).thenAnswer(
      (_) async => const [
        MyDayShelfRate(
          shelf: MyDayDecisionShelf.planned,
          numerator: 3,
          denominator: 5,
        ),
      ],
    );
    when(
      () => repository.getDeferRateByShelf(range: any(named: 'range')),
    ).thenAnswer(
      (_) async => const [
        MyDayShelfRate(
          shelf: MyDayDecisionShelf.due,
          numerator: 2,
          denominator: 4,
        ),
      ],
    );
    when(
      () => repository.getEntityDeferCounts(
        range: any(named: 'range'),
        entityType: any(named: 'entityType'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const [
        MyDayEntityDeferCount(
          entityType: MyDayDecisionEntityType.task,
          entityId: 'task-1',
          deferCount: 2,
          snoozeCount: 1,
        ),
      ],
    );
    when(
      () => repository.getRoutineTopCompletionWeekdays(
        range: any(named: 'range'),
        topPerRoutine: any(named: 'topPerRoutine'),
        limitRoutines: any(named: 'limitRoutines'),
      ),
    ).thenAnswer(
      (_) async => const [
        RoutineWeekdayStat(routineId: 'routine-1', weekdayLocal: 2, count: 4),
      ],
    );
    when(
      () => repository.getDeferredThenCompletedLag(
        range: any(named: 'range'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const [
        DeferredThenCompletedLagMetric(
          entityType: MyDayDecisionEntityType.task,
          entityId: 'task-1',
          sampleSize: 2,
          medianLagHours: 10,
          p75LagHours: 16,
          completedWithin7DaysRate: 1,
        ),
      ],
    );
  });

  blocTestSafe<DebugStatsBloc, DebugStatsState>(
    'loads stats on start',
    build: () => DebugStatsBloc(repository: repository, nowService: nowService),
    act: (bloc) => bloc.add(const DebugStatsStarted()),
    expect: () => [
      isA<DebugStatsState>().having((s) => s.loading, 'loading', true),
      isA<DebugStatsState>()
          .having((s) => s.loading, 'loading', false)
          .having((s) => s.keepRates.length, 'keep rates', 1)
          .having((s) => s.deferRates.length, 'defer rates', 1)
          .having((s) => s.routineWeekdays.length, 'routine weekdays', 1),
    ],
  );
}
