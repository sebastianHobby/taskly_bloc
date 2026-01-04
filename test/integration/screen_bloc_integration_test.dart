/// Integration tests for ScreenBloc.
///
/// These tests verify the screen loading and data flow from
/// repository through interpreter to bloc state.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/screen_source.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';

import '../helpers/bloc_test_patterns.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════════════════

class MockScreenDefinitionsRepository extends Mock
    implements ScreenDefinitionsRepositoryContract {}

class MockScreenDataInterpreter extends Mock implements ScreenDataInterpreter {}

// Fallback for mocktail any() matching
class FakeDataDrivenScreenDefinition extends Fake
    implements DataDrivenScreenDefinition {}

// ═══════════════════════════════════════════════════════════════════════════
// Test Helpers
// ═══════════════════════════════════════════════════════════════════════════

final _fixedTime = DateTime(2024, 1, 1);

DataDrivenScreenDefinition _createScreenDefinition({
  String id = 'test-screen',
  String screenKey = 'test-screen-key',
  String name = 'Test Screen',
}) {
  return DataDrivenScreenDefinition(
    id: id,
    screenKey: screenKey,
    name: name,
    screenType: ScreenType.list,
    sections: [
      Section.data(
        config: DataConfig.task(query: TaskQuery.all()),
        title: 'Tasks',
      ),
    ],
    createdAt: _fixedTime,
    updatedAt: _fixedTime,
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.workspace,
  );
}

NavigationOnlyScreenDefinition _createNavOnlyScreen({
  String id = 'nav-screen',
  String screenKey = 'nav-screen-key',
  String name = 'Nav Screen',
}) {
  return NavigationOnlyScreenDefinition(
    id: id,
    screenKey: screenKey,
    name: name,
    createdAt: _fixedTime,
    updatedAt: _fixedTime,
    screenSource: ScreenSource.systemTemplate,
    category: ScreenCategory.settings,
  );
}

ScreenData _createScreenData(DataDrivenScreenDefinition definition) {
  return ScreenData(
    definition: definition,
    sections: const [],
    supportBlocks: const [],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(FakeDataDrivenScreenDefinition());
  });

  group('ScreenBloc Integration', () {
    late MockScreenDefinitionsRepository mockScreenRepo;
    late MockScreenDataInterpreter mockInterpreter;
    late DataDrivenScreenDefinition testDefinition;
    late ScreenData testScreenData;

    setUp(() {
      mockScreenRepo = MockScreenDefinitionsRepository();
      mockInterpreter = MockScreenDataInterpreter();
      testDefinition = _createScreenDefinition();
      testScreenData = _createScreenData(testDefinition);
    });

    group('load event', () {
      blocTestSafe<ScreenBloc, ScreenState>(
        'emits loading then loaded when load succeeds',
        setUp: () {
          // Use any() for any DataDrivenScreenDefinition argument
          when(
            () => mockInterpreter.watchScreen(any()),
          ).thenAnswer((_) => Stream.value(testScreenData));
        },
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) => bloc.add(ScreenEvent.load(definition: testDefinition)),
        expect: () => [
          isA<ScreenLoadingState>(),
          isA<ScreenLoadedState>(),
        ],
      );

      blocTestSafe<ScreenBloc, ScreenState>(
        'emits error for navigation-only screen',
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) {
          final navScreen = _createNavOnlyScreen();
          bloc.add(ScreenEvent.load(definition: navScreen));
        },
        expect: () => [
          isA<ScreenErrorState>().having(
            (s) => s.message,
            'message',
            contains('navigation-only'),
          ),
        ],
      );

      blocTestSafe<ScreenBloc, ScreenState>(
        'handles stream errors gracefully',
        setUp: () {
          when(() => mockInterpreter.watchScreen(any())).thenAnswer(
            (_) => Stream.error(Exception('Stream failed')),
          );
        },
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) => bloc.add(ScreenEvent.load(definition: testDefinition)),
        expect: () => [
          isA<ScreenLoadingState>(),
          isA<ScreenErrorState>(),
        ],
      );
    });

    group('loadById event', () {
      blocTestSafe<ScreenBloc, ScreenState>(
        'emits loading then loaded when loadById succeeds',
        setUp: () {
          when(() => mockScreenRepo.watchScreen('inbox')).thenAnswer(
            (_) => Stream.value(
              ScreenWithPreferences(
                screen: testDefinition,
                preferences: const ScreenPreferences(
                  isActive: true,
                  sortOrder: 0,
                ),
              ),
            ),
          );

          when(
            () => mockInterpreter.watchScreen(any()),
          ).thenAnswer((_) => Stream.value(testScreenData));
        },
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) => bloc.add(const ScreenEvent.loadById(screenId: 'inbox')),
        expect: () => [
          isA<ScreenLoadingState>(),
          isA<ScreenLoadingState>().having(
            (s) => s.definition,
            'definition',
            isNotNull,
          ),
          isA<ScreenLoadedState>(),
        ],
      );

      blocTestSafe<ScreenBloc, ScreenState>(
        'emits error when screen not found',
        setUp: () {
          when(() => mockScreenRepo.watchScreen('missing')).thenAnswer(
            (_) => Stream.value(null),
          );
        },
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) =>
            bloc.add(const ScreenEvent.loadById(screenId: 'missing')),
        expect: () => [
          isA<ScreenLoadingState>(),
          isA<ScreenErrorState>().having(
            (s) => s.message,
            'message',
            contains('not found'),
          ),
        ],
      );

      blocTestSafe<ScreenBloc, ScreenState>(
        'emits error when loadById returns navigation-only screen',
        setUp: () {
          final navScreen = _createNavOnlyScreen(screenKey: 'settings');

          when(() => mockScreenRepo.watchScreen('settings')).thenAnswer(
            (_) => Stream.value(
              ScreenWithPreferences(
                screen: navScreen,
                preferences: const ScreenPreferences(
                  isActive: true,
                  sortOrder: 100,
                ),
              ),
            ),
          );
        },
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) =>
            bloc.add(const ScreenEvent.loadById(screenId: 'settings')),
        expect: () => [
          isA<ScreenLoadingState>(),
          isA<ScreenErrorState>().having(
            (s) => s.message,
            'message',
            contains('navigation-only'),
          ),
        ],
      );
    });

    group('refresh event', () {
      blocTestSafe<ScreenBloc, ScreenState>(
        'refresh does nothing when no screen loaded',
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) => bloc.add(const ScreenEvent.refresh()),
        expect: () => <ScreenState>[],
      );
    });

    group('reset event', () {
      blocTestSafe<ScreenBloc, ScreenState>(
        'reset returns to initial state',
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        seed: () => ScreenState.loaded(data: testScreenData),
        act: (bloc) => bloc.add(const ScreenEvent.reset()),
        expect: () => [
          isA<ScreenInitialState>(),
        ],
      );
    });

    group('data flow', () {
      blocTestSafe<ScreenBloc, ScreenState>(
        'emits error state when interpreter returns error data',
        setUp: () {
          final errorData = ScreenData.error(
            testDefinition,
            'Data fetch failed',
          );

          when(
            () => mockInterpreter.watchScreen(any()),
          ).thenAnswer((_) => Stream.value(errorData));
        },
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) => bloc.add(ScreenEvent.load(definition: testDefinition)),
        expect: () => [
          isA<ScreenLoadingState>(),
          isA<ScreenErrorState>().having(
            (s) => s.message,
            'message',
            'Data fetch failed',
          ),
        ],
      );

      blocTestSafe<ScreenBloc, ScreenState>(
        'emits multiple loaded states as data streams',
        setUp: () {
          final data1 = testScreenData;
          final data2 = ScreenData(
            definition: testDefinition,
            sections: const [
              SectionDataWithMeta(
                index: 0,
                result: SectionDataResult.data(
                  primaryEntityType: 'task',
                  primaryEntities: [],
                ),
              ),
            ],
            supportBlocks: const [],
          );

          when(() => mockInterpreter.watchScreen(any())).thenAnswer(
            (_) => Stream.fromIterable([data1, data2]),
          );
        },
        build: () => ScreenBloc(
          screenRepository: mockScreenRepo,
          interpreter: mockInterpreter,
        ),
        act: (bloc) => bloc.add(ScreenEvent.load(definition: testDefinition)),
        expect: () => [
          isA<ScreenLoadingState>(),
          isA<ScreenLoadedState>(),
          isA<ScreenLoadedState>(),
        ],
      );
    });
  });
}
