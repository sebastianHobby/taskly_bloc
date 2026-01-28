@Tags(['unit', 'scope_context'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/scope_context/bloc/scope_context_bloc.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockValueRepositoryContract valueRepository;

  late TestStreamController<int> taskCountController;
  late TestStreamController<int> projectCountController;
  late TestStreamController<Project?> projectController;
  late TestStreamController<Value?> valueController;

  setUp(() {
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    valueRepository = MockValueRepositoryContract();

    taskCountController = TestStreamController.seeded(0);
    projectCountController = TestStreamController.seeded(0);
    projectController = TestStreamController.seeded(
      TestData.project(id: 'p1', name: 'Alpha'),
    );
    valueController = TestStreamController.seeded(
      TestData.value(id: 'v1', name: 'Purpose'),
    );

    when(() => taskRepository.watchAllCount(any())).thenAnswer(
      (_) => taskCountController.stream,
    );
    when(() => projectRepository.watchAllCount(any())).thenAnswer(
      (_) => projectCountController.stream,
    );
    when(() => projectRepository.watchById(any())).thenAnswer(
      (_) => projectController.stream,
    );
    when(() => valueRepository.watchById(any())).thenAnswer(
      (_) => valueController.stream,
    );

    addTearDown(taskCountController.close);
    addTearDown(projectCountController.close);
    addTearDown(projectController.close);
    addTearDown(valueController.close);
  });

  blocTestSafe<ScopeContextBloc, ScopeContextState>(
    'loads project scope title and task count',
    build: () => ScopeContextBloc(
      scope: const AnytimeProjectScope(projectId: 'p1'),
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      valueRepository: valueRepository,
    ),
    act: (_) {
      taskCountController.emit(3);
    },
    expect: () => [
      isA<ScopeContextLoaded>()
          .having((s) => s.title, 'title', 'Alpha')
          .having((s) => s.taskCount, 'taskCount', 0),
      isA<ScopeContextLoaded>()
          .having((s) => s.title, 'title', 'Alpha')
          .having((s) => s.taskCount, 'taskCount', 3),
    ],
  );

  blocTestSafe<ScopeContextBloc, ScopeContextState>(
    'loads value scope title with project counts',
    build: () => ScopeContextBloc(
      scope: const AnytimeValueScope(valueId: 'v1'),
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      valueRepository: valueRepository,
    ),
    act: (_) {
      taskCountController.emit(2);
      projectCountController.emit(5);
    },
    expect: () => [
      isA<ScopeContextLoaded>()
          .having((s) => s.title, 'title', 'Purpose')
          .having((s) => s.taskCount, 'taskCount', 0)
          .having((s) => s.projectCount, 'projectCount', 0),
      isA<ScopeContextLoaded>()
          .having((s) => s.title, 'title', 'Purpose')
          .having((s) => s.taskCount, 'taskCount', 2)
          .having((s) => s.projectCount, 'projectCount', 5),
    ],
  );

  blocTestSafe<ScopeContextBloc, ScopeContextState>(
    'retry exits loading after error',
    build: () => ScopeContextBloc(
      scope: const AnytimeProjectScope(projectId: 'p1'),
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      valueRepository: valueRepository,
    ),
    act: (bloc) async {
      taskCountController.emitError(StateError('boom'));
      await Future<void>.delayed(TestConstants.defaultWait);
      bloc.add(const ScopeContextRetryRequested());
      taskCountController.emit(1);
    },
    expect: () => [
      isA<ScopeContextLoaded>(),
      isA<ScopeContextError>(),
      isA<ScopeContextLoading>(),
      isA<ScopeContextLoaded>().having((s) => s.taskCount, 'taskCount', 1),
    ],
  );
}

