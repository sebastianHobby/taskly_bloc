@Tags(['unit', 'anytime'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_scope_picker_bloc.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockSessionSharedDataService sharedDataService;
  late TestStreamController<List<Value>> valuesController;
  late TestStreamController<List<Project>> projectsController;

  AnytimeScopePickerBloc buildBloc() {
    return AnytimeScopePickerBloc(sharedDataService: sharedDataService);
  }

  setUp(() {
    sharedDataService = MockSessionSharedDataService();
    valuesController = TestStreamController.seeded([
      TestData.value(id: 'v-low', name: 'Low', priority: ValuePriority.low),
      TestData.value(id: 'v-high', name: 'High', priority: ValuePriority.high),
    ]);
    projectsController = TestStreamController.seeded([
      TestData.project(id: 'p2', name: 'Beta'),
      TestData.project(id: 'p1', name: 'Alpha'),
    ]);

    when(() => sharedDataService.watchValues()).thenAnswer(
      (_) => valuesController.stream,
    );
    when(() => sharedDataService.watchAllProjects()).thenAnswer(
      (_) => projectsController.stream,
    );

    addTearDown(valuesController.close);
    addTearDown(projectsController.close);
  });

  blocTestSafe<AnytimeScopePickerBloc, AnytimeScopePickerState>(
    'emits loaded state with sorted values and projects',
    build: buildBloc,
    expect: () => [
      isA<AnytimeScopePickerLoaded>()
          .having((s) => s.values.first.priority, 'value.priority', ValuePriority.high)
          .having((s) => s.projects.first.name, 'project.name', 'Alpha'),
    ],
  );

  blocTestSafe<AnytimeScopePickerBloc, AnytimeScopePickerState>(
    'updates when streams emit new values',
    build: buildBloc,
    act: (_) {
      valuesController.emit([
        TestData.value(id: 'v-high', name: 'High', priority: ValuePriority.high),
        TestData.value(id: 'v-mid', name: 'Mid', priority: ValuePriority.medium),
      ]);
    },
    expect: () => [
      isA<AnytimeScopePickerLoaded>(),
      isA<AnytimeScopePickerLoaded>()
          .having((s) => s.values.length, 'values.length', 2),
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
      isA<AnytimeScopePickerLoaded>()
          .having((s) => s.values.length, 'values.length', 1),
    ],
  );
}

