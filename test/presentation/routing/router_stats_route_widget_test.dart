@Tags(['widget', 'routing'])
library;

import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/features/statistics/view/debug_stats_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/routing/not_found_route_page.dart';
import 'package:taskly_bloc/presentation/routing/router.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart';

import '../../helpers/test_imports.dart';

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

  testWidgetsSafe('routes /settings/developer/stats with debug gate', (
    tester,
  ) async {
    final repository = _MockRepo();
    final nowService = _MockNowService();
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2026, 2, 24));
    when(
      () => repository.getKeepRateByShelf(range: any(named: 'range')),
    ).thenAnswer((_) async => const <MyDayShelfRate>[]);
    when(
      () => repository.getDeferRateByShelf(range: any(named: 'range')),
    ).thenAnswer((_) async => const <MyDayShelfRate>[]);
    when(
      () => repository.getEntityDeferCounts(
        range: any(named: 'range'),
        entityType: any(named: 'entityType'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const <MyDayEntityDeferCount>[]);
    when(
      () => repository.getRoutineTopCompletionWeekdays(
        range: any(named: 'range'),
        topPerRoutine: any(named: 'topPerRoutine'),
        limitRoutines: any(named: 'limitRoutines'),
      ),
    ).thenAnswer((_) async => const <RoutineWeekdayStat>[]);
    when(
      () => repository.getDeferredThenCompletedLag(
        range: any(named: 'range'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const <DeferredThenCompletedLagMetric>[]);

    final router = GoRouter(
      initialLocation: '/settings/developer/stats',
      routes: [
        GoRoute(
          path: '/settings/developer/stats',
          builder: (_, __) => MultiProvider(
            providers: [
              Provider<MyDayDecisionEventRepositoryContract>.value(
                value: repository,
              ),
              Provider<NowService>.value(value: nowService),
            ],
            child: buildSettingsStatsRoutePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);

    if (kDebugMode) {
      expect(find.byType(DebugStatsPage), findsOneWidget);
      expect(find.byType(NotFoundRoutePage), findsNothing);
    } else {
      expect(find.byType(DebugStatsPage), findsNothing);
      expect(find.byType(NotFoundRoutePage), findsOneWidget);
    }
  });
}
