@Tags(['unit', 'scheduled'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_scope_header_bloc.dart';
import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockProjectRepositoryContract projectRepository;
  late MockValueRepositoryContract valueRepository;
  late TestStreamController<Project?> projectController;
  late TestStreamController<Value?> valueController;

  setUp(() {
    projectRepository = MockProjectRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    projectController = TestStreamController.seeded(
      TestData.project(id: 'p1', name: 'Alpha'),
    );
    valueController = TestStreamController.seeded(
      TestData.value(id: 'v1', name: 'Purpose'),
    );

    when(() => projectRepository.watchById(any())).thenAnswer(
      (_) => projectController.stream,
    );
    when(() => valueRepository.watchById(any())).thenAnswer(
      (_) => valueController.stream,
    );

    addTearDown(projectController.close);
    addTearDown(valueController.close);
  });

  blocTestSafe<ScheduledScopeHeaderBloc, ScheduledScopeHeaderState>(
    'loads project scope title',
    build: () => ScheduledScopeHeaderBloc(
      scope: const ProjectScheduledScope(projectId: 'p1'),
      projectRepository: projectRepository,
      valueRepository: valueRepository,
    ),
    expect: () => [
      isA<ScheduledScopeHeaderLoaded>().having(
        (s) => s.title,
        'title',
        'Project: Alpha',
      ),
    ],
  );

  blocTestSafe<ScheduledScopeHeaderBloc, ScheduledScopeHeaderState>(
    'loads value scope title',
    build: () => ScheduledScopeHeaderBloc(
      scope: const ValueScheduledScope(valueId: 'v1'),
      projectRepository: projectRepository,
      valueRepository: valueRepository,
    ),
    expect: () => [
      isA<ScheduledScopeHeaderLoaded>().having(
        (s) => s.title,
        'title',
        'Value: Purpose',
      ),
    ],
  );

  blocTestSafe<ScheduledScopeHeaderBloc, ScheduledScopeHeaderState>(
    'retry exits loading after missing project',
    build: () => ScheduledScopeHeaderBloc(
      scope: const ProjectScheduledScope(projectId: 'p1'),
      projectRepository: projectRepository,
      valueRepository: valueRepository,
    ),
    act: (bloc) async {
      projectController.emit(null);
      await Future<void>.delayed(TestConstants.defaultWait);
      bloc.add(const ScheduledScopeHeaderRetryRequested());
      projectController.emit(TestData.project(id: 'p1', name: 'Alpha'));
    },
    expect: () => [
      isA<ScheduledScopeHeaderLoaded>(),
      isA<ScheduledScopeHeaderError>(),
      isA<ScheduledScopeHeaderLoading>(),
      isA<ScheduledScopeHeaderLoaded>(),
      isA<ScheduledScopeHeaderLoaded>(),
    ],
  );
}
