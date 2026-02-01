@Tags(['unit', 'projects'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/project_picker/bloc/project_picker_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late SessionSharedDataService sharedDataService;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockValueRepositoryContract valueRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late BehaviorSubject<List<Project>> projectsSubject;

  ProjectPickerBloc buildBloc() {
    return ProjectPickerBloc(sharedDataService: sharedDataService);
  }

  setUp(() {
    appLifecycleEvents = MockAppLifecycleEvents();
    valueRepository = MockValueRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    projectsSubject = BehaviorSubject<List<Project>>();
    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => projectRepository.watchAll()).thenAnswer(
      (_) => projectsSubject.stream,
    );
    when(() => projectRepository.getAll()).thenAnswer(
      (_) async => const <Project>[],
    );
    when(() => projectRepository.getAll(any())).thenAnswer(
      (_) async => const <Project>[],
    );

    cacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );
    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
    addTearDown(projectsSubject.close);
    addTearDown(cacheManager.dispose);
    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<ProjectPickerBloc, ProjectPickerState>(
    'loads and filters projects',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const ProjectPickerStarted());
      projectsSubject.add([
        TestData.project(id: 'p2', name: 'Bravo'),
        TestData.project(id: 'p1', name: 'Alpha'),
      ]);
      bloc.add(const ProjectPickerSearchChanged(query: 'bra'));
    },
    expect: () => [
      isA<ProjectPickerState>(),
      isA<ProjectPickerState>(),
      isA<ProjectPickerState>(),
      isA<ProjectPickerState>(),
    ],
    verify: (bloc) {
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.allProjects.first.name, 'Alpha');
      expect(bloc.state.visibleProjects.length, 1);
      expect(bloc.state.visibleProjects.first.name, 'Bravo');
      expect(bloc.state.query, 'bra');
    },
  );
}
