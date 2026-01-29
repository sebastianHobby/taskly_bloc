@Tags(['widget', 'anytime'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/anytime/view/anytime_page.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_domain/core.dart';

class MockAnytimeSessionQueryService extends Mock
    implements AnytimeSessionQueryService {}

class MockEditorLauncher extends Mock implements EditorLauncher {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAnytimeSessionQueryService queryService;
  late MockEditorLauncher editorLauncher;
  late BehaviorSubject<AnytimeProjectsSnapshot> projectsSubject;

  setUp(() {
    queryService = MockAnytimeSessionQueryService();
    editorLauncher = MockEditorLauncher();
    projectsSubject = BehaviorSubject<AnytimeProjectsSnapshot>();

    when(
      () => queryService.watchProjects(scope: any(named: 'scope')),
    ).thenAnswer((_) => projectsSubject);
  });

  tearDown(() async {
    await projectsSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AnytimeSessionQueryService>.value(
            value: queryService,
          ),
          RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
        ],
        child: const AnytimePage(),
      ),
    );
  }

  testWidgetsSafe('shows loading state before feed emits', (tester) async {
    await pumpPage(tester);

    expect(find.byKey(const ValueKey('feed-loading')), findsOneWidget);
  });

  testWidgetsSafe('shows error state when feed stream errors', (tester) async {
    await pumpPage(tester);

    projectsSubject.addError(Exception('boom'));
    await tester.pumpForStream();

    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgetsSafe('renders project content when loaded', (tester) async {
    await pumpPage(tester);

    final project = TestData.project(name: 'Project Alpha');
    projectsSubject.add(
      AnytimeProjectsSnapshot(
        projects: [project],
        inboxTaskCount: 0,
        values: const <Value>[],
      ),
    );
    await tester.pumpForStream();

    expect(find.text('Project Alpha'), findsOneWidget);
  });

  testWidgetsSafe('updates list when feed emits new data', (tester) async {
    await pumpPage(tester);

    final projectA = TestData.project(name: 'Project A');
    projectsSubject.add(
      AnytimeProjectsSnapshot(
        projects: [projectA],
        inboxTaskCount: 0,
        values: const <Value>[],
      ),
    );
    await tester.pumpForStream();
    expect(find.text('Project A'), findsOneWidget);

    final projectB = TestData.project(name: 'Project B');
    projectsSubject.add(
      AnytimeProjectsSnapshot(
        projects: [projectA, projectB],
        inboxTaskCount: 0,
        values: const <Value>[],
      ),
    );
    await tester.pumpForStream();

    expect(find.text('Project B'), findsOneWidget);
  });
}
