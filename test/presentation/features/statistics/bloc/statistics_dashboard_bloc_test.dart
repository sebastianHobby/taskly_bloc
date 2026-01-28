@Tags(['unit', 'statistics'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/statistics/bloc/statistics_dashboard_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(TestData.dateRange());
  });
  setUp(setUpTestEnvironment);

  late MockAnalyticsService analyticsService;
  late MockValueRepositoryContract valueRepository;
  late MockNowService nowService;

  StatisticsDashboardBloc buildBloc() {
    return StatisticsDashboardBloc(
      analyticsService: analyticsService,
      valueRepository: valueRepository,
      nowService: nowService,
      defaultRangeDays: 30,
    );
  }

  setUp(() {
    analyticsService = MockAnalyticsService();
    valueRepository = MockValueRepositoryContract();
    nowService = MockNowService();

    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15));
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => [TestData.value(id: 'v-1', name: 'Value')],
    );
    when(
      () => analyticsService.getRecentCompletionsByValue(days: any(named: 'days')),
    ).thenAnswer((_) async => {'v-1': 3});
    when(() => analyticsService.getValuePrimarySecondaryStats()).thenAnswer(
      (_) async => const {},
    );
    when(
      () => analyticsService.getValueWeeklyTrends(weeks: any(named: 'weeks')),
    ).thenAnswer((_) async => {'v-1': [0.2, 0.3]});
    when(
      () => analyticsService.getMoodTrend(
        range: any(named: 'range'),
        granularity: any(named: 'granularity'),
      ),
    ).thenAnswer(
      (_) async => TrendData(
        points: const [],
        granularity: TrendGranularity.weekly,
      ),
    );
    when(
      () => analyticsService.getMoodDistribution(range: any(named: 'range')),
    ).thenAnswer((_) async => const {3: 1});
    when(
      () => analyticsService.getMoodSummary(range: any(named: 'range')),
    ).thenAnswer(
      (_) async => const MoodSummary(
        average: 3.0,
        totalEntries: 1,
        min: 3,
        max: 3,
        distribution: {3: 1},
      ),
    );
    when(
      () => analyticsService.getTopMoodCorrelations(range: any(named: 'range')),
    ).thenAnswer((_) async => [TestData.correlation()]);
  });

  blocTestSafe<StatisticsDashboardBloc, StatisticsDashboardState>(
    'loads sections and marks ready',
    build: buildBloc,
    act: (bloc) => bloc.add(const StatisticsDashboardRequested()),
    expect: () => [
      isA<StatisticsDashboardState>()
          .having((s) => s.valuesFocus.status, 'valuesFocus', StatisticsSectionStatus.loading),
      isA<StatisticsDashboardState>()
          .having((s) => s.valuesFocus.status, 'valuesFocus', StatisticsSectionStatus.ready),
      isA<StatisticsDashboardState>()
          .having((s) => s.valueTrends.status, 'valueTrends', StatisticsSectionStatus.ready),
      isA<StatisticsDashboardState>()
          .having((s) => s.moodStats.status, 'moodStats', StatisticsSectionStatus.ready),
      isA<StatisticsDashboardState>()
          .having((s) => s.correlations.status, 'correlations', StatisticsSectionStatus.ready),
    ],
  );
}
