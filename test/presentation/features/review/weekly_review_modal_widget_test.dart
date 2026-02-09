@Tags(['widget', 'review'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/services.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAttentionEngine extends Mock implements AttentionEngineContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockValueRatingsRepository extends Mock
    implements ValueRatingsRepositoryContract {}

class MockRoutineRepository extends Mock implements RoutineRepositoryContract {}

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

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
    registerFallbackValue(const AttentionQuery());
  });
  setUp(setUpTestEnvironment);

  late MockAnalyticsService analyticsService;
  late MockAttentionEngine attentionEngine;
  late MockValueRepository valueRepository;
  late MockValueRatingsRepository valueRatingsRepository;
  late ValueRatingsWriteService valueRatingsWriteService;
  late MockRoutineRepository routineRepository;
  late MockTaskRepository taskRepository;
  late MockGlobalSettingsBloc globalSettingsBloc;

  setUp(() {
    analyticsService = MockAnalyticsService();
    attentionEngine = MockAttentionEngine();
    valueRepository = MockValueRepository();
    valueRatingsRepository = MockValueRatingsRepository();
    valueRatingsWriteService = ValueRatingsWriteService(
      repository: valueRatingsRepository,
    );
    routineRepository = MockRoutineRepository();
    taskRepository = MockTaskRepository();
    globalSettingsBloc = MockGlobalSettingsBloc();

    when(() => globalSettingsBloc.state).thenReturn(
      const GlobalSettingsState(isLoading: false),
    );

    when(
      () => attentionEngine.watch(any()),
    ).thenAnswer((_) => const Stream<List<AttentionItem>>.empty());
    when(() => valueRepository.getAll()).thenAnswer((_) async => <Value>[]);
    when(
      () => valueRatingsRepository.getAll(weeks: any(named: 'weeks')),
    ).thenAnswer((_) async => <ValueWeeklyRating>[]);
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => <Routine>[]);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => <RoutineSkip>[]);
    when(
      () => taskRepository.getSnoozeStats(
        sinceUtc: any(named: 'sinceUtc'),
        untilUtc: any(named: 'untilUtc'),
      ),
    ).thenAnswer((_) async => <String, TaskSnoozeStats>{});
    when(
      () => taskRepository.getByIds(any()),
    ).thenAnswer((_) async => <Task>[]);

    when(
      () => analyticsService.getRecentCompletionsByValue(
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => <String, int>{});
    when(
      () => analyticsService.getValueWeeklyTrends(weeks: any(named: 'weeks')),
    ).thenAnswer((_) async => <String, List<double>>{});
  });

  Future<void> pumpModal(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AnalyticsService>.value(value: analyticsService),
          RepositoryProvider<AttentionEngineContract>.value(
            value: attentionEngine,
          ),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
          RepositoryProvider<ValueRatingsRepositoryContract>.value(
            value: valueRatingsRepository,
          ),
          RepositoryProvider<ValueRatingsWriteService>.value(
            value: valueRatingsWriteService,
          ),
          RepositoryProvider<RoutineRepositoryContract>.value(
            value: routineRepository,
          ),
          RepositoryProvider<TaskRepositoryContract>.value(
            value: taskRepository,
          ),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: BlocProvider<GlobalSettingsBloc>.value(
          value: globalSettingsBloc,
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => showWeeklyReviewModal(
                        context,
                        settings: const GlobalSettings(),
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<AppLocalizations> l10nFor() {
    return AppLocalizations.delegate.load(const Locale('en'));
  }

  testWidgetsSafe('shows loading state while weekly review loads', (
    tester,
  ) async {
    final completer = Completer<List<Value>>();
    when(() => valueRepository.getAll()).thenAnswer((_) => completer.future);

    await pumpModal(tester);
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpForStream();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    completer.complete(<Value>[]);
  });

  testWidgetsSafe('shows error state when weekly review fails', (tester) async {
    when(() => valueRepository.getAll()).thenThrow('review failed');

    await pumpModal(tester);
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpForStream();

    final l10n = await l10nFor();
    expect(find.text(l10n.weeklyReviewLoadFailureMessage), findsOneWidget);
  });

  testWidgetsSafe('renders weekly review content when loaded', (tester) async {
    await pumpModal(tester);
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpForStream();

    final l10n = await l10nFor();
    expect(find.text(l10n.weeklyReviewTitle), findsOneWidget);
  });
}
