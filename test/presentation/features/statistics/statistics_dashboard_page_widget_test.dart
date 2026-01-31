@Tags(['widget', 'statistics'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/statistics/view/statistics_dashboard_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class FakeNowService implements NowService {
  FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAnalyticsService analyticsService;
  late MockValueRepository valueRepository;

  setUp(() {
    analyticsService = MockAnalyticsService();
    valueRepository = MockValueRepository();

    when(
      () => analyticsService.getRecentCompletionsByValue(
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => <String, int>{});
    when(
      () => analyticsService.getValuePrimarySecondaryStats(),
    ).thenAnswer((_) async => <String, ValuePrimarySecondaryStats>{});
    when(
      () => analyticsService.getValueWeeklyTrends(weeks: any(named: 'weeks')),
    ).thenAnswer((_) async => <String, List<double>>{});
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
      () => analyticsService.getTopMoodCorrelations(
        range: any(named: 'range'),
      ),
    ).thenAnswer((_) async => <CorrelationResult>[]);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AnalyticsService>.value(value: analyticsService),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: const StatisticsDashboardPage(),
      ),
    );
  }

  testWidgetsSafe('shows loading sections while dashboard loads', (
    tester,
  ) async {
    final completer = Completer<List<Value>>();
    when(() => valueRepository.getAll()).thenAnswer((_) => completer.future);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Loading...'), findsWidgets);

    completer.complete(const <Value>[]);
  });

  testWidgetsSafe('shows section error when analytics fails', (tester) async {
    when(
      () => valueRepository.getAll(),
    ).thenAnswer((_) async => <Value>[TestData.value(name: 'Value A')]);
    when(
      () => analyticsService.getRecentCompletionsByValue(
        days: any(named: 'days'),
      ),
    ).thenThrow('values failed');

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('values failed'), findsOneWidget);
  });

  testWidgetsSafe('renders value content when loaded', (tester) async {
    final value = TestData.value(id: 'v-1', name: 'Value A');
    when(() => valueRepository.getAll()).thenAnswer((_) async => [value]);
    when(
      () => analyticsService.getRecentCompletionsByValue(
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => {'v-1': 3});
    when(
      () => analyticsService.getValueWeeklyTrends(weeks: any(named: 'weeks')),
    ).thenAnswer(
      (_) async => {
        'v-1': [0.2, 0.3],
      },
    );
    when(
      () => analyticsService.getTopMoodCorrelations(
        range: any(named: 'range'),
      ),
    ).thenAnswer((_) async => [TestData.correlation()]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Value A'), findsWidgets);
  });
}
