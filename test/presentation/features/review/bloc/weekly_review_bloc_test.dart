@Tags(['unit', 'review'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAnalyticsService analyticsService;
  late MockAttentionEngineContract attentionEngine;
  late MockValueRepositoryContract valueRepository;
  late MockValueRatingsRepositoryContract valueRatingsRepository;
  late ValueRatingsWriteService valueRatingsWriteService;
  late MockRoutineRepositoryContract routineRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockNowService nowService;

  WeeklyReviewBloc buildBloc() {
    return WeeklyReviewBloc(
      analyticsService: analyticsService,
      attentionEngine: attentionEngine,
      valueRepository: valueRepository,
      valueRatingsRepository: valueRatingsRepository,
      valueRatingsWriteService: valueRatingsWriteService,
      routineRepository: routineRepository,
      taskRepository: taskRepository,
      nowService: nowService,
    );
  }

  setUp(() {
    analyticsService = MockAnalyticsService();
    attentionEngine = MockAttentionEngineContract();
    valueRepository = MockValueRepositoryContract();
    valueRatingsRepository = MockValueRatingsRepositoryContract();
    valueRatingsWriteService = ValueRatingsWriteService(
      repository: valueRatingsRepository,
    );
    routineRepository = MockRoutineRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    nowService = MockNowService();

    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15));
    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15));
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => [TestData.value(id: 'v-1', name: 'Value')],
    );
    when(
      () => analyticsService.getRecentCompletionsByValue(
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => {'v-1': 3});
    when(
      () => analyticsService.getRecentTaskCompletionsCount(
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => 3);
    when(
      () => analyticsService.getValueWeeklyTrends(weeks: any(named: 'weeks')),
    ).thenAnswer(
      (_) async => {
        'v-1': [0.2, 0.3],
      },
    );
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => []);
    when(() => routineRepository.getCompletions()).thenAnswer(
      (_) async => [],
    );
    when(
      () => valueRatingsRepository.getAll(weeks: any(named: 'weeks')),
    ).thenAnswer(
      (_) async => [],
    );
    when(
      () => valueRatingsRepository.upsertWeeklyRating(
        valueId: any(named: 'valueId'),
        weekStartUtc: any(named: 'weekStartUtc'),
        rating: any(named: 'rating'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(() => attentionEngine.watch(any())).thenAnswer(
      (_) => const Stream<List<AttentionItem>>.empty(),
    );
    when(
      () => taskRepository.getSnoozeStats(
        sinceUtc: any(named: 'sinceUtc'),
        untilUtc: any(named: 'untilUtc'),
      ),
    ).thenAnswer((_) async => {});
    when(() => taskRepository.getByIds(any())).thenAnswer((_) async => []);
    when(() => taskRepository.watchCompletionHistory()).thenAnswer(
      (_) => Stream.value(const <CompletionHistoryData>[]),
    );
  });

  blocTestSafe<WeeklyReviewBloc, WeeklyReviewState>(
    'requested loads ratings summary when values exist',
    build: buildBloc,
    act: (bloc) => bloc.add(
      WeeklyReviewRequested(
        WeeklyReviewConfig(
          checkInWindowWeeks: 4,
          maintenanceEnabled: false,
          showDeadlineRisk: false,
          showStaleItems: false,
          taskStaleThresholdDays: 14,
          projectIdleThresholdDays: 14,
          deadlineRiskDueWithinDays: 3,
          deadlineRiskMinUnscheduledCount: 2,
          showFrequentSnoozed: false,
        ),
      ),
    ),
    expect: () => [
      isA<WeeklyReviewState>().having(
        (s) => s.status,
        'status',
        WeeklyReviewStatus.loading,
      ),
      isA<WeeklyReviewState>()
          .having((s) => s.status, 'status', WeeklyReviewStatus.ready)
          .having(
            (s) => s.ratingsSummary?.ratingsEnabled,
            'ratingsEnabled',
            true,
          )
          .having((s) => s.ratingsSummary?.entries.length, 'entries', 1),
    ],
  );

  blocTestSafe<WeeklyReviewBloc, WeeklyReviewState>(
    'requested enables ratings even when values are empty',
    build: buildBloc,
    setUp: () {
      when(() => valueRepository.getAll()).thenAnswer((_) async => []);
    },
    act: (bloc) => bloc.add(
      WeeklyReviewRequested(
        WeeklyReviewConfig(
          checkInWindowWeeks: 4,
          maintenanceEnabled: false,
          showDeadlineRisk: false,
          showStaleItems: false,
          taskStaleThresholdDays: 14,
          projectIdleThresholdDays: 14,
          deadlineRiskDueWithinDays: 3,
          deadlineRiskMinUnscheduledCount: 2,
          showFrequentSnoozed: false,
        ),
      ),
    ),
    expect: () => [
      isA<WeeklyReviewState>().having(
        (s) => s.status,
        'status',
        WeeklyReviewStatus.loading,
      ),
      isA<WeeklyReviewState>()
          .having((s) => s.status, 'status', WeeklyReviewStatus.ready)
          .having(
            (s) => s.ratingsSummary?.ratingsEnabled,
            'ratingsEnabled',
            true,
          ),
    ],
  );

  blocTestSafe<WeeklyReviewBloc, WeeklyReviewState>(
    'requested includes ratings entries and maintenance sections when enabled',
    build: buildBloc,
    setUp: () {
      when(() => valueRepository.getAll()).thenAnswer(
        (_) async => [
          TestData.value(id: 'v-1', name: 'Value 1'),
          TestData.value(id: 'v-2', name: 'Value 2'),
        ],
      );
    },
    act: (bloc) => bloc.add(
      WeeklyReviewRequested(
        WeeklyReviewConfig(
          checkInWindowWeeks: 4,
          maintenanceEnabled: true,
          showDeadlineRisk: true,
          showStaleItems: true,
          taskStaleThresholdDays: 14,
          projectIdleThresholdDays: 14,
          deadlineRiskDueWithinDays: 3,
          deadlineRiskMinUnscheduledCount: 2,
          showFrequentSnoozed: true,
        ),
      ),
    ),
    expect: () => [
      isA<WeeklyReviewState>().having(
        (s) => s.status,
        'status',
        WeeklyReviewStatus.loading,
      ),
      isA<WeeklyReviewState>()
          .having((s) => s.status, 'status', WeeklyReviewStatus.ready)
          .having(
            (s) => s.ratingsSummary?.entries.length,
            'ratings entries',
            2,
          )
          .having(
            (s) => s.maintenanceSections.length,
            'maintenance sections',
            3,
          ),
    ],
  );

  blocTestSafe<WeeklyReviewBloc, WeeklyReviewState>(
    'value rating change records ratings with context',
    build: buildBloc,
    seed: () => WeeklyReviewState(
      status: WeeklyReviewStatus.ready,
      ratingsSummary: WeeklyReviewRatingsSummary(
        weekStartUtc: DateTime.utc(2025, 1, 13),
        entries: [
          WeeklyReviewRatingEntry(
            value: TestData.value(id: 'v-1', name: 'Value'),
            rating: 0,
            lastRating: null,
            weeksSinceLastRating: null,
            history: const [],
            taskCompletions: 0,
            routineCompletions: 0,
            trend: const [],
          ),
        ],
        maxRating: 10,
        graceWeeks: 2,
        ratingsEnabled: true,
        ratingsOverdue: false,
        ratingsInGrace: false,
        selectedValueId: 'v-1',
      ),
    ),
    act: (bloc) => bloc.add(
      const WeeklyReviewValueRatingChanged(valueId: 'v-1', rating: 5),
    ),
    expect: () => [
      isA<WeeklyReviewState>().having(
        (s) => s.ratingsSummary?.selectedValueId,
        'selected',
        'v-1',
      ),
    ],
    verify: (_) {
      final captured = verify(
        () => valueRatingsRepository.upsertWeeklyRating(
          valueId: 'v-1',
          weekStartUtc: any(named: 'weekStartUtc'),
          rating: 5,
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.feature, 'weekly_review');
      expect(ctx.screen, 'weekly_review');
      expect(ctx.intent, 'rate_value');
      expect(ctx.operation, 'value.rating.upsert');
      expect(ctx.entityId, 'v-1');
    },
  );

  blocTestSafe<WeeklyReviewBloc, WeeklyReviewState>(
    'evidence requested loads task and routine evidence',
    build: buildBloc,
    setUp: () {
      final value = TestData.value(id: 'v-1', name: 'Value');
      when(() => taskRepository.watchCompletionHistory()).thenAnswer(
        (_) => Stream.value(
          [
            CompletionHistoryData(
              id: 'c-1',
              entityId: 'task-1',
              completedAt: DateTime.utc(2025, 1, 14),
            ),
          ],
        ),
      );
      when(() => taskRepository.getByIds(any())).thenAnswer(
        (_) async => [
          TestData.task(
            id: 'task-1',
            name: 'Task',
            values: [value],
          ),
        ],
      );
      when(() => routineRepository.getAll(includeInactive: true)).thenAnswer(
        (_) async => [
          Routine(
            id: 'routine-1',
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
            name: 'Routine',
            valueId: 'v-1',
            routineType: RoutineType.weeklyFixed,
            targetCount: 1,
          ),
        ],
      );
      when(() => routineRepository.getCompletions()).thenAnswer(
        (_) async => [
          RoutineCompletion(
            id: 'rc-1',
            routineId: 'routine-1',
            completedAtUtc: DateTime.utc(2025, 1, 13),
            createdAtUtc: DateTime.utc(2025, 1, 13),
          ),
        ],
      );
    },
    act: (bloc) => bloc.add(
      const WeeklyReviewEvidenceRequested(
        valueId: 'v-1',
        range: WeeklyReviewEvidenceRange.lastWeek,
      ),
    ),
    expect: () => [
      isA<WeeklyReviewState>().having(
        (s) => s.evidence?.status,
        'status',
        WeeklyReviewEvidenceStatus.loading,
      ),
      isA<WeeklyReviewState>()
          .having(
            (s) => s.evidence?.status,
            'status',
            WeeklyReviewEvidenceStatus.ready,
          )
          .having(
            (s) => s.evidence?.taskItems.length,
            'task items',
            1,
          )
          .having(
            (s) => s.evidence?.routineItems.length,
            'routine items',
            1,
          ),
    ],
  );
}
