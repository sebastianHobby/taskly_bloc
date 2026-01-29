@Tags(['widget', 'scheduled'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_scope_header.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/taskly_domain.dart';

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
  late BehaviorSubject<Project?> projectSubject;

  setUp(() {
    projectRepository = MockProjectRepository();
    valueRepository = MockValueRepository();
    projectSubject = BehaviorSubject<Project?>();

    when(
      () => projectRepository.watchById(any()),
    ).thenAnswer((_) => projectSubject.stream);
    when(
      () => valueRepository.watchById(any()),
    ).thenAnswer((_) => const Stream<Value?>.empty());
  });

  tearDown(() async {
    await projectSubject.close();
  });

  Future<void> pumpHeader(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ProjectRepositoryContract>.value(
            value: projectRepository,
          ),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
        ],
        child: const ScheduledScopeHeader(
          scope: ProjectScheduledScope(projectId: 'project-1'),
        ),
      ),
    );
  }

  testWidgetsSafe('shows loading placeholder before scope loads', (
    tester,
  ) async {
    await pumpHeader(tester);

    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgetsSafe('shows project title when loaded', (tester) async {
    await pumpHeader(tester);

    projectSubject.add(TestData.project(name: 'Inbox'));
    await tester.pumpForStream();

    expect(find.text('Project: Inbox'), findsOneWidget);
  });

  testWidgetsSafe('shows error message when stream errors', (tester) async {
    await pumpHeader(tester);

    projectSubject.addError(Exception('fail'));
    await tester.pumpForStream();

    expect(find.text('Failed to load project'), findsOneWidget);
  });
}
