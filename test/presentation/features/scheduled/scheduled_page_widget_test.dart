@Tags(['widget', 'scheduled'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/presentation_mocks.dart';
import '../../../mocks/fake_repositories.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_page.dart';
import 'package:taskly_bloc/presentation/features/scheduled/services/scheduled_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';

class MockEditorLauncher extends Mock implements EditorLauncher {}

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

  late ScheduledOccurrencesService occurrencesService;
  late ScheduledSessionQueryService queryService;
  late SessionStreamCacheManager cacheManager;
  late OccurrenceReadService occurrenceReadService;
  late MockOccurrenceStreamExpanderContract occurrenceExpander;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late TaskWriteService taskWriteService;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockOccurrenceCommandService occurrenceCommandService;
  late ProjectWriteService projectWriteService;
  late MockEditorLauncher editorLauncher;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late TestStreamController<TemporalTriggerEvent> temporalController;
  const speedDialInitDelay = Duration(milliseconds: 1);

  setUp(() {
    demoModeService = DemoModeService()..enable();
    demoDataProvider = DemoDataProvider();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    occurrenceCommandService = MockOccurrenceCommandService();
    taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceCommandService: occurrenceCommandService,
    );
    projectWriteService = ProjectWriteService(
      projectRepository: projectRepository,
      occurrenceCommandService: occurrenceCommandService,
    );
    editorLauncher = MockEditorLauncher();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    temporalController = TestStreamController.seeded(const AppResumed());
    occurrenceExpander = MockOccurrenceStreamExpanderContract();
    occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      dayKeyService: dayKeyService,
      occurrenceExpander: occurrenceExpander,
    );
    occurrencesService = ScheduledOccurrencesService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceReadService: occurrenceReadService,
    );
    cacheManager = SessionStreamCacheManager(
      appLifecycleService: const _StaticLifecycleEvents(),
    )..start();
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );
    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));
    sessionDayKeyService.start();
    queryService = ScheduledSessionQueryService(
      scheduledOccurrencesService: occurrencesService,
      sessionDayKeyService: sessionDayKeyService,
      cacheManager: cacheManager,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
  });

  tearDown(() async {
    await temporalController.close();
    await cacheManager.dispose();
    await sessionDayKeyService.dispose();
    await demoModeService.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/scheduled',
      routes: [
        GoRoute(
          path: '/scheduled',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ScheduledSessionQueryService>.value(
                value: queryService,
              ),
              RepositoryProvider<TaskWriteService>.value(
                value: taskWriteService,
              ),
              RepositoryProvider<ProjectWriteService>.value(
                value: projectWriteService,
              ),
              RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
              RepositoryProvider<SessionDayKeyService>.value(
                value: sessionDayKeyService,
              ),
              RepositoryProvider<NowService>.value(
                value: FakeNowService(DateTime(2025, 1, 15, 9)),
              ),
              RepositoryProvider<DemoModeService>.value(
                value: demoModeService,
              ),
              RepositoryProvider<DemoDataProvider>.value(
                value: demoDataProvider,
              ),
              RepositoryProvider<SettingsRepositoryContract>.value(
                value: FakeSettingsRepository(),
              ),
            ],
            child: const ScheduledPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);
    await tester.pump(speedDialInitDelay);
  }

  testWidgetsSafe('renders schedule header in demo mode', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    final l10n = _l10n(tester);
    final foundTitle = await tester.pumpUntilFound(
      find.text(l10n.scheduledTitle),
    );
    expect(foundTitle, isTrue);
    expect(find.text(l10n.scheduledTitle), findsOneWidget);
  });

  testWidgetsSafe('renders demo scheduled items', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    final foundItem = await tester.pumpUntilFound(
      find.text('Complete Lesson 3'),
    );
    expect(foundItem, isTrue);
    expect(find.text('Complete Lesson 3'), findsOneWidget);
  });
}

AppLocalizations _l10n(WidgetTester tester) {
  return tester.element(find.byType(ScheduledPage)).l10n;
}

final class _StaticLifecycleEvents implements AppLifecycleEvents {
  const _StaticLifecycleEvents();

  @override
  Stream<AppLifecycleEvent> get events =>
      const Stream<AppLifecycleEvent>.empty();
}
