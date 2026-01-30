@Tags(['unit', 'anytime'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_scope_picker_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late SessionSharedDataService sharedDataService;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockValueRepositoryContract valueRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;
  late TestStreamController<List<Value>> valuesController;
  late TestStreamController<List<Project>> projectsController;

  AnytimeScopePickerBloc buildBloc() {
    return AnytimeScopePickerBloc(sharedDataService: sharedDataService);
  }

  setUp(() {
    appLifecycleEvents = MockAppLifecycleEvents();
    valueRepository = MockValueRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    valuesController = TestStreamController.seeded([
      TestData.value(id: 'v-low', name: 'Low', priority: ValuePriority.low),
      TestData.value(id: 'v-high', name: 'High', priority: ValuePriority.high),
    ]);
    projectsController = TestStreamController.seeded([
      TestData.project(id: 'p2', name: 'Beta'),
      TestData.project(id: 'p1', name: 'Alpha'),
    ]);

    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => valueRepository.watchAll()).thenAnswer(
      (_) => valuesController.stream,
    );
    when(() => projectRepository.watchAll()).thenAnswer(
      (_) => projectsController.stream,
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

    addTearDown(valuesController.close);
    addTearDown(projectsController.close);
    addTearDown(cacheManager.dispose);
    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<AnytimeScopePickerBloc, AnytimeScopePickerState>(
    'emits loaded state with sorted values and projects',
    build: buildBloc,
    expect: () => [
      isA<AnytimeScopePickerLoaded>()
          .having(
            (s) => s.values.first.priority,
            'value.priority',
            ValuePriority.high,
          )
          .having((s) => s.projects.first.name, 'project.name', 'Alpha'),
    ],
  );

  blocTestSafe<AnytimeScopePickerBloc, AnytimeScopePickerState>(
    'updates when streams emit new values',
    build: buildBloc,
    act: (_) {
      valuesController.emit([
        TestData.value(
          id: 'v-high',
          name: 'High',
          priority: ValuePriority.high,
        ),
        TestData.value(
          id: 'v-mid',
          name: 'Mid',
          priority: ValuePriority.medium,
        ),
      ]);
    },
    expect: () => [
      isA<AnytimeScopePickerLoaded>(),
      isA<AnytimeScopePickerLoaded>().having(
        (s) => s.values.length,
        'values.length',
        2,
      ),
    ],
  );

  blocTestSafe<AnytimeScopePickerBloc, AnytimeScopePickerState>(
    'retry exits loading after stream error',
    build: buildBloc,
    act: (bloc) async {
      valuesController.emitError(StateError('boom'));
      await Future<void>.delayed(TestConstants.defaultWait);
      bloc.add(const AnytimeScopePickerRetryRequested());
      valuesController.emit([
        TestData.value(id: 'v-ok', name: 'Ok', priority: ValuePriority.medium),
      ]);
    },
    expect: () => [
      isA<AnytimeScopePickerLoaded>(),
      isA<AnytimeScopePickerError>(),
      isA<AnytimeScopePickerLoading>(),
      isA<AnytimeScopePickerError>(),
      isA<AnytimeScopePickerLoaded>(),
      isA<AnytimeScopePickerLoaded>().having(
        (s) => s.values.length,
        'values.length',
        1,
      ),
    ],
  );
}
