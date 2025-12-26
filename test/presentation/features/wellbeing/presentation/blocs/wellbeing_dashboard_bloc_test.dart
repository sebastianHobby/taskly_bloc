import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/correlation_result.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/date_range.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/trend_data.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/services/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/presentation/blocs/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late AnalyticsService analyticsService;
  late WellbeingDashboardBloc bloc;

  setUpAll(() {
    registerFallbackValue(DateRange.last30Days());
  });

  setUp(() {
    analyticsService = MockAnalyticsService();
  });

  tearDown(() {
    bloc.close();
  });

  final testDateRange = DateRange.last30Days();
  final testMoodTrend = TrendData(
    dates: [DateTime(2025)],
    values: [4.5],
    average: 4.5,
    change: 0.0,
  );
  final testCorrelations = [
    CorrelationResult(
      factorName: 'Exercise',
      correlation: 0.85,
      significance: 0.01,
      sampleSize: 30,
    ),
  ];

  group('WellbeingDashboardBloc', () {
    test('automatically loads on initialization', () async {
      when(
        () => analyticsService.getMoodTrend(range: any(named: 'range')),
      ).thenAnswer((_) async => testMoodTrend);
      when(
        () => analyticsService.getTopMoodCorrelations(
          range: any(named: 'range'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => testCorrelations);

      bloc = WellbeingDashboardBloc(analyticsService);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.moodTrend, isNotNull);
      expect(bloc.state.topCorrelations, isNotNull);
    });

    group('load', () {
      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'emits loading state then loaded state when services succeed',
        build: () {
          when(
            () => analyticsService.getMoodTrend(range: any(named: 'range')),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any(named: 'range'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2, // Skip initial auto-load emissions
        expect: () => [
          const WellbeingDashboardState(isLoading: true),
          WellbeingDashboardState(
            isLoading: false,
            moodTrend: testMoodTrend,
            topCorrelations: testCorrelations,
          ),
        ],
        verify: (_) {
          verify(
            () => analyticsService.getMoodTrend(range: testDateRange),
          ).called(1);
          verify(
            () => analyticsService.getTopMoodCorrelations(
              range: testDateRange,
              limit: 5,
            ),
          ).called(1);
        },
      );

      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'emits error state when getMoodTrend fails',
        build: () {
          when(
            () => analyticsService.getMoodTrend(range: any(named: 'range')),
          ).thenThrow(Exception('Failed to load mood trend'));
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any(named: 'range'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(isLoading: true),
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
            () => analyticsService.getMoodTrend(range: any(named: 'range')),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any(named: 'range'),
              limit: any(named: 'limit'),
            ),
          ).thenThrow(Exception('Failed to load correlations'));
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(isLoading: true),
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
            () => analyticsService.getMoodTrend(range: any(named: 'range')),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any(named: 'range'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => []);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) =>
            bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange)),
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(isLoading: true),
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
            () => analyticsService.getMoodTrend(range: any(named: 'range')),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any(named: 'range'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) => bloc.add(
          WellbeingDashboardEvent.load(dateRange: DateRange.last7Days()),
        ),
        skip: 2,
        verify: (_) {
          verify(
            () => analyticsService.getMoodTrend(
              range: DateRange.last7Days(),
            ),
          ).called(1);
        },
      );

      blocTest<WellbeingDashboardBloc, WellbeingDashboardState>(
        'loads data for custom date range',
        build: () {
          when(
            () => analyticsService.getMoodTrend(range: any(named: 'range')),
          ).thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any(named: 'range'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) {
          final customRange = DateRange(
            start: DateTime(2025),
            end: DateTime(2025, 1, 31),
          );
          return bloc.add(
            WellbeingDashboardEvent.load(dateRange: customRange),
          );
        },
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(isLoading: true),
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
          when(() => analyticsService.getMoodTrend(range: any(named: 'range')))
              .thenThrow(Exception('Error'))
              .thenAnswer((_) async => testMoodTrend);
          when(
            () => analyticsService.getTopMoodCorrelations(
              range: any(named: 'range'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => testCorrelations);
          return WellbeingDashboardBloc(analyticsService);
        },
        act: (bloc) {
          bloc.add(WellbeingDashboardEvent.load(dateRange: testDateRange));
          return Future.delayed(
            const Duration(milliseconds: 100),
            () => bloc.add(
              WellbeingDashboardEvent.load(dateRange: testDateRange),
            ),
          );
        },
        skip: 2,
        expect: () => [
          const WellbeingDashboardState(isLoading: true),
          const WellbeingDashboardState(
            isLoading: false,
            error: 'Exception: Error',
          ),
          const WellbeingDashboardState(isLoading: true),
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
