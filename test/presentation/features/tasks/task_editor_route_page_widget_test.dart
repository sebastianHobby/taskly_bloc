@Tags(['widget', 'tasks'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

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

  late MockTaskRepository taskRepository;
  late MockProjectRepository projectRepository;
  late MockValueRepository valueRepository;
  late MockMyDayRepositoryContract myDayRepository;
  late MockSettingsRepositoryContract settingsRepository;
  late TaskWriteService taskWriteService;
  late TaskMyDayWriteService taskMyDayWriteService;
  late AppErrorReporter errorReporter;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;

  setUp(() {
    taskRepository = MockTaskRepository();
    projectRepository = MockProjectRepository();
    valueRepository = MockValueRepository();
    myDayRepository = MockMyDayRepositoryContract();
    settingsRepository = MockSettingsRepositoryContract();
    taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceCommandService: MockOccurrenceCommandService(),
    );
    taskMyDayWriteService = TaskMyDayWriteService(
      taskWriteService: taskWriteService,
      myDayRepository: myDayRepository,
      dayKeyService: HomeDayKeyService(
        settingsRepository: settingsRepository,
      ),
    );
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();

    when(() => projectRepository.getAll()).thenAnswer((_) async => const []);
    when(() => valueRepository.getAll()).thenAnswer((_) async => const []);
  });

  tearDown(() async {
    await demoModeService.dispose();
  });

  Future<void> pumpRoute(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/task/new',
          builder: (context, state) => const TaskEditorRoutePage(
            taskId: null,
          ),
        ),
      ],
      initialLocation: '/task/new',
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TaskRepositoryContract>.value(
            value: taskRepository,
          ),
          RepositoryProvider<ProjectRepositoryContract>.value(
            value: projectRepository,
          ),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
          RepositoryProvider<TaskWriteService>.value(value: taskWriteService),
          RepositoryProvider<TaskMyDayWriteService>.value(
            value: taskMyDayWriteService,
          ),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
          RepositoryProvider<DemoModeService>.value(value: demoModeService),
          RepositoryProvider<DemoDataProvider>.value(value: demoDataProvider),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgetsSafe('renders task editor full page for deep link', (
    tester,
  ) async {
    await pumpRoute(tester);
    await tester.pumpForStream();

    expect(find.byType(TaskForm), findsOneWidget);
  });
}
