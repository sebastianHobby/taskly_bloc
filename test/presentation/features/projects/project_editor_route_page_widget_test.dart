@Tags(['widget', 'projects'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_form.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockProjectRepository projectRepository;
  late MockValueRepository valueRepository;
  late MockAllocationOrchestrator allocationOrchestrator;
  late MockOccurrenceCommandService occurrenceCommandService;
  late ProjectWriteService projectWriteService;
  late AppErrorReporter errorReporter;

  setUp(() {
    projectRepository = MockProjectRepository();
    valueRepository = MockValueRepository();
    allocationOrchestrator = MockAllocationOrchestrator();
    occurrenceCommandService = MockOccurrenceCommandService();
    projectWriteService = ProjectWriteService(
      projectRepository: projectRepository,
      allocationOrchestrator: allocationOrchestrator,
      occurrenceCommandService: occurrenceCommandService,
    );
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );

    when(() => valueRepository.getAll()).thenAnswer((_) async => const []);
  });

  Future<void> pumpRoute(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/project/new',
          builder: (context, state) => const ProjectEditorRoutePage(
            projectId: null,
          ),
        ),
      ],
      initialLocation: '/project/new',
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ProjectRepositoryContract>.value(
            value: projectRepository,
          ),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
          RepositoryProvider<ProjectWriteService>.value(
            value: projectWriteService,
          ),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
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

  testWidgetsSafe('renders project editor full page for deep link', (
    tester,
  ) async {
    await pumpRoute(tester);
    await tester.pumpForStream();

    expect(find.byType(ProjectForm), findsOneWidget);
  });
}
