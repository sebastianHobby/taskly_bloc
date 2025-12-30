import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late AnalyticsService analyticsService;

  setUpAll(() {
    registerFallbackValue(DateRange.last30Days());
  });

  setUp(() {
    analyticsService = MockAnalyticsService();
  });

  final testDateRange = DateRange.last30Days();
  final testMoodTrend = TrendData(
    points: [
      TrendPoint(
        date: DateTime(2025),
        value: 4.5,
      ),
    ],
    granularity: TrendGranularity.daily,
    average: 4.5,
  );
  final testCorrelations = [
    CorrelationResult(
      sourceLabel: 'Exercise',
      targetLabel: 'Mood',
      coefficient: 0.85,
      strength: CorrelationStrength.strongPositive,
      sampleSize: 30,
    ),
  ];

  group('WellbeingDashboardBloc', () {
    test('automatically loads on initialization', () async {
      when(
        () => analyticsService.getMoodTrend(
          range: any<DateRange>(named: 'range'),
        ),
      ).thenAnswer((_) async => testMoodTrend);
      when(
        () => analyticsService.getTopMoodCorrelations(
          range: any<DateRange>(named: 'range'),
          limit: any<int>(named: 'limit'),
        ),
      ).thenAnswer((_) async => testCorrelations);

      final bloc = WellbeingDashboardBloc(analyticsService);
      addTearDown(bloc.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.moodTrend, isNotNull);
      expect(bloc.state.topCorrelations, isNotNull);
    });

    group('load', () {
      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'emits loading state then loaded state when services succeed',
        build: () {
          when(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any<DateRange>(named: 'range'),
              limit: any<int>(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2, // Skip initial auto-load emissions
        expect: () => [
          WellbeingDashboardState(
            moodTrend: testMoodTrend,
            topCorrelations: testCorrelations,
          ),
          WellbeingDashboardState(
            isLoading: false,
            moodTrend: testMoodTrend,
            topCorrelations: testCorrelations,
          ),
        ],
        verify: (_) {
          verify(
            () => analyticsService.getMoodTrend(range: testDateRange),
          ).called(2);
          verify(
            () => analyticsService.getTopMoodCorrelations(
              range: testDateRange,
              limit: 5,
            ),
          ).called(2);
        },
      );

      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'emits error state when getMoodTrend fails',
        build: () {
          when(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).thenThrow(Exception('Failed to load mood trend'));
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any<DateRange>(named: 'range'),
              limit: any<int>(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(),
          const WellbeingDashboardState(
            isLoading: false,
            error: 'Exception: Failed to load mood trend',
          ),
        ],
      );

      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'emits error state when getTopMoodCorrelations fails',
        build: () {
          when(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any<DateRange>(named: 'range'),
              limit: any<int>(named: 'limit'),
            ),
          ).thenThrow(Exception('Failed to load correlations'));
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(),
          const WellbeingDashboardState(
            isLoading: false,
            error: 'Exception: Failed to load correlations',
          ),
        ],
      );

      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'handles empty correlation results',
        build: () {
          when(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any<DateRange>(named: 'range'),
              limit: any<int>(named: 'limit'),
            ),
          ).thenAnswer((_) async => []);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2,
        expect: () => [
          WellbeingDashboardState(
            moodTrend: testMoodTrend,
            topCorrelations: [],
          ),
          WellbeingDashboardState(
            isLoading: false,
            moodTrend: testMoodTrend,
            topCorrelations: [],
          ),
        ],
      );
    });

    group('different date ranges', () {
      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'loads data for last 7 days',
        build: () {
          when(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any<DateRange>(named: 'range'),
              limit: any<int>(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) {
          final last7DaysRange = DateRange(
            start: DateTime(2025),
            end: DateTime(2025, 1, 8),
          );
          bloc.add(WellbeingDashboardEvent.load(dateRange: last7DaysRange));
        },
        skip: 2,
        verify: (_) {
          verify(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).called(2);
        },
      );

      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'loads data for custom date range',
        build: () {
          when(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any<DateRange>(named: 'range'),
              limit: any<int>(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) {
          final customRange = DateRange(
            start: DateTime(2025),
            end: DateTime(2025, 1, 31),
          );
          bloc.add(WellbeingDashboardEvent.load(dateRange: customRange));
        },
        skip: 2,
        expect: () => [
          WellbeingDashboardState(
            moodTrend: testMoodTrend,
            topCorrelations: testCorrelations,
          ),
          WellbeingDashboardState(
            isLoading: false,
            moodTrend: testMoodTrend,
            topCorrelations: testCorrelations,
          ),
        ],
      );
    });

    group('state management', () {
      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'clears error when reloading',
        build: () {
          var callCount = 0;
          when(
            () => analyticsService.getMoodTrend(
              range: any<DateRange>(named: 'range'),
            ),
          ).thenAnswer((_) async {
            callCount++;
            if (callCount <= 2) {
              throw Exception('Error');
            }
            return testMoodTrend;
          });
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any<DateRange>(named: 'range'),
              limit: any<int>(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) async {
          bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange));
        },
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(),
          const WellbeingDashboardState(
            isLoading: false,
            error: 'Exception: Error',
          ),
          const WellbeingDashboardState(),
          WellbeingDashboardState(
            isLoading: false,
            moodTrend: testMoodTrend,
            topCorrelations: testCorrelations,
          ),
        ],
      );
    });
  });
}
