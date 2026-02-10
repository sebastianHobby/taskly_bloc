@Tags(['widget', 'onboarding'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/onboarding/view/onboarding_flow_page.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';

class MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAttentionEngine extends Mock implements AttentionEngineContract {}

class MockValueRatingsRepository extends Mock
    implements ValueRatingsRepositoryContract {}

class MockRoutineRepository extends Mock implements RoutineRepositoryContract {}

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockNowService extends Mock implements NowService {}

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(const AllocationConfig());
  });
  setUp(setUpTestEnvironment);

  late MockSettingsRepository settingsRepository;
  late MockValueRepository valueRepository;
  late MockAnalyticsService analyticsService;
  late MockAttentionEngine attentionEngine;
  late MockValueRatingsRepository valueRatingsRepository;
  late ValueRatingsWriteService valueRatingsWriteService;
  late MockRoutineRepository routineRepository;
  late MockTaskRepository taskRepository;
  late MockNowService nowService;
  late ValueWriteService valueWriteService;
  late AppErrorReporter errorReporter;
  late MockGlobalSettingsBloc globalSettingsBloc;

  setUp(() {
    settingsRepository = MockSettingsRepository();
    valueRepository = MockValueRepository();
    analyticsService = MockAnalyticsService();
    attentionEngine = MockAttentionEngine();
    valueRatingsRepository = MockValueRatingsRepository();
    valueRatingsWriteService = ValueRatingsWriteService(
      repository: valueRatingsRepository,
    );
    routineRepository = MockRoutineRepository();
    taskRepository = MockTaskRepository();
    nowService = MockNowService();
    valueWriteService = ValueWriteService(valueRepository: valueRepository);
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    globalSettingsBloc = MockGlobalSettingsBloc();

    when(() => globalSettingsBloc.state).thenReturn(
      const GlobalSettingsState(isLoading: false),
    );
    when(() => settingsRepository.load(SettingsKey.allocation)).thenAnswer(
      (_) async => const AllocationConfig(),
    );
    when(
      () => settingsRepository.save(
        SettingsKey.allocation,
        any<AllocationConfig>(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SettingsRepositoryContract>.value(
            value: settingsRepository,
          ),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
          RepositoryProvider<AnalyticsService>.value(value: analyticsService),
          RepositoryProvider<AttentionEngineContract>.value(
            value: attentionEngine,
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
          RepositoryProvider<NowService>.value(value: nowService),
          RepositoryProvider<ValueWriteService>.value(value: valueWriteService),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
          ],
          child: const OnboardingFlowPage(),
        ),
      ),
    );
  }

  testWidgetsSafe('shows welcome step content', (tester) async {
    await pumpPage(tester);

    final l10n = _l10n(tester);
    expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
    expect(find.text(l10n.onboardingGetStartedLabel), findsOneWidget);
  });

  testWidgetsSafe('shows values step after tapping get started', (
    tester,
  ) async {
    await pumpPage(tester);

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.onboardingGetStartedLabel));
    final found = await tester.pumpUntilFound(
      find.text(l10n.onboardingValuesTitle),
    );
    expect(found, isTrue);
  });
}

AppLocalizations _l10n(WidgetTester tester) {
  return tester.element(find.byType(OnboardingFlowPage)).l10n;
}
