/// Integration tests for ScreenBloc.
///
/// These tests verify the screen loading and data flow from
/// repository through interpreter to bloc state.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_source.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_state.dart';

import '../helpers/bloc_test_patterns.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════════════════

class MockScreenDefinitionsRepository extends Mock
    implements ScreenDefinitionsRepositoryContract {}

class MockScreenDataInterpreter extends Mock implements ScreenDataInterpreter {}

// ═══════════════════════════════════════════════════════════════════════════
// Test Helpers
// ═══════════════════════════════════════════════════════════════════════════

final _fixedTime = DateTime(2024, 1, 1);

ScreenDefinition _createScreenDefinition({
  String id = 'test-screen',
  String screenKey = 'test-screen-key',
  String name = 'Test Screen',
}) {
  return ScreenDefinition(
    id: id,
    screenKey: screenKey,
    name: name,
    createdAt: _fixedTime,
    updatedAt: _fixedTime,
    screenSource: ScreenSource.systemTemplate,
    sections: const [
      SectionRef(templateId: SectionTemplateId.taskList),
    ],
  );
}

ScreenData _createScreenData(ScreenDefinition definition) {
  return ScreenData(
    definition: definition,
    sections: const [],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(_createScreenDefinition());
  });

  group('ScreenBloc Integration', () {
    late MockScreenDefinitionsRepository mockScreenRepo;
    late MockScreenDataInterpreter mockInterpreter;
    late ScreenDefinition testDefinition;
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
          when(() => mockScreenRepo.watchScreen('my_day')).thenAnswer(
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
        act: (bloc) => bloc.add(const ScreenEvent.loadById(screenId: 'my_day')),
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
              SectionVm(
                index: 0,
                templateId: SectionTemplateId.taskList,
                params: <String, dynamic>{},
                data: SectionDataResult.data(items: <ScreenItem>[]),
              ),
            ],
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
