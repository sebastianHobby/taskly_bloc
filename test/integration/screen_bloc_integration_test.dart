import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

import '../helpers/bloc_test_patterns.dart';

class MockScreenDataInterpreter extends Mock implements ScreenDataInterpreter {}

void main() {
  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(_createScreenDefinition());
  });

  group('ScreenBloc (integration-ish)', () {
    late MockScreenDataInterpreter mockInterpreter;
    late ScreenDefinition testDefinition;
    late ScreenData testScreenData;

    setUp(() {
      mockInterpreter = MockScreenDataInterpreter();
      testDefinition = _createScreenDefinition();
      testScreenData = _createScreenData(testDefinition);
    });

    blocTestSafe<ScreenBloc, ScreenState>(
      'emits loading then loaded when interpreter emits data',
      setUp: () {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(testScreenData),
        );
      },
      build: () => ScreenBloc(
        interpreter: mockInterpreter,
        performanceLogger: PerformanceLogger(),
      ),
      act: (bloc) => bloc.add(ScreenEvent.load(definition: testDefinition)),
      expect: () => [
        isA<ScreenLoadingState>(),
        isA<ScreenLoadedState>(),
      ],
    );

    blocTestSafe<ScreenBloc, ScreenState>(
      'emits error when interpreter stream throws',
      setUp: () {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream<ScreenData>.error(Exception('Stream failed')),
        );
      },
      build: () => ScreenBloc(
        interpreter: mockInterpreter,
        performanceLogger: PerformanceLogger(),
      ),
      act: (bloc) => bloc.add(ScreenEvent.load(definition: testDefinition)),
      expect: () => [
        isA<ScreenLoadingState>(),
        isA<ScreenErrorState>(),
      ],
    );

    blocTestSafe<ScreenBloc, ScreenState>(
      'emits error when interpreter emits error data',
      setUp: () {
        final errorData = ScreenData.error(testDefinition, 'Data fetch failed');
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(errorData),
        );
      },
      build: () => ScreenBloc(
        interpreter: mockInterpreter,
        performanceLogger: PerformanceLogger(),
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
      'emits multiple loaded states as data updates arrive',
      setUp: () {
        final data1 = testScreenData;
        final data2 = ScreenData(
          definition: testDefinition,
          sections: const [],
        );

        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.fromIterable([data1, data2]),
        );
      },
      build: () => ScreenBloc(
        interpreter: mockInterpreter,
        performanceLogger: PerformanceLogger(),
      ),
      act: (bloc) => bloc.add(ScreenEvent.load(definition: testDefinition)),
      expect: () => [
        isA<ScreenLoadingState>(),
        isA<ScreenLoadedState>(),
        isA<ScreenLoadedState>(),
      ],
    );
  });
}

ScreenDefinition _createScreenDefinition() {
  return ScreenDefinition(
    id: 'my_day',
    screenKey: 'my_day',
    name: 'My Day',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    sections: const [
      SectionRef(templateId: 'test-template'),
    ],
  );
}

ScreenData _createScreenData(ScreenDefinition definition) {
  return ScreenData(
    definition: definition,
    sections: const [],
  );
}
