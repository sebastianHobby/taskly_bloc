@Tags(['widget', 'scheduled'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/presentation_mocks.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_page.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
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
  late OccurrenceReadService occurrenceReadService;
  late MockOccurrenceStreamExpanderContract occurrenceExpander;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late TaskWriteService taskWriteService;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockAllocationOrchestrator allocationOrchestrator;
  late MockOccurrenceCommandService occurrenceCommandService;
  late ProjectWriteService projectWriteService;
  late MockEditorLauncher editorLauncher;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late TestStreamController<TemporalTriggerEvent> temporalController;

  setUp(() {
    demoModeService = DemoModeService()..enable();
    demoDataProvider = DemoDataProvider();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    allocationOrchestrator = MockAllocationOrchestrator();
    occurrenceCommandService = MockOccurrenceCommandService();
    taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      allocationOrchestrator: allocationOrchestrator,
      occurrenceCommandService: occurrenceCommandService,
    );
    projectWriteService = ProjectWriteService(
      projectRepository: projectRepository,
      allocationOrchestrator: allocationOrchestrator,
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

  });

  tearDown(() async {
    await temporalController.close();
    await sessionDayKeyService.dispose();
    await demoModeService.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ScheduledOccurrencesService>.value(
            value: occurrencesService,
          ),
          RepositoryProvider<TaskWriteService>.value(value: taskWriteService),
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
          RepositoryProvider<DemoModeService>.value(value: demoModeService),
          RepositoryProvider<DemoDataProvider>.value(value: demoDataProvider),
        ],
        child: const ScheduledPage(),
      ),
    );
  }

  testWidgetsSafe('renders schedule header in demo mode', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Schedule'), findsOneWidget);
  });

  testWidgetsSafe('renders demo scheduled items', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Complete Lesson 3'), findsOneWidget);
  });
}
