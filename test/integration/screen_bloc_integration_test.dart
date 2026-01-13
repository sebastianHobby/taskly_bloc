import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

import '../helpers/bloc_test_patterns.dart';

class MockScreenSpecDataInterpreter extends Mock
    implements ScreenSpecDataInterpreter {}

const _testSpec = ScreenSpec(
  id: 'test-spec',
  screenKey: 'test_screen',
  name: 'Test Screen',
  template: ScreenTemplateSpec.standardScaffoldV1(),
);

ScreenSpecData _data({String? error}) {
  return ScreenSpecData(
    spec: _testSpec,
    template: _testSpec.template,
    sections: const SlottedSectionVms(),
    error: error,
  );
}

void main() {
  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(_testSpec);
  });

  group('ScreenSpecBloc (integration-ish)', () {
    late MockScreenSpecDataInterpreter mockInterpreter;

    setUp(() {
      mockInterpreter = MockScreenSpecDataInterpreter();
    });

    blocTestSafe<ScreenSpecBloc, ScreenSpecState>(
      'emits loading then loaded when interpreter emits data',
      setUp: () {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(_data()),
        );
      },
      build: () => ScreenSpecBloc(interpreter: mockInterpreter),
      act: (bloc) => bloc.add(const ScreenSpecLoadEvent(spec: _testSpec)),
      expect: () => [
        isA<ScreenSpecLoadingState>(),
        isA<ScreenSpecLoadedState>(),
      ],
    );

    blocTestSafe<ScreenSpecBloc, ScreenSpecState>(
      'emits error when interpreter stream throws',
      setUp: () {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream<ScreenSpecData>.error(Exception('Stream failed')),
        );
      },
      build: () => ScreenSpecBloc(interpreter: mockInterpreter),
      act: (bloc) => bloc.add(const ScreenSpecLoadEvent(spec: _testSpec)),
      expect: () => [
        isA<ScreenSpecLoadingState>(),
        isA<ScreenSpecErrorState>(),
      ],
    );

    blocTestSafe<ScreenSpecBloc, ScreenSpecState>(
      'emits error when interpreter emits error data',
      setUp: () {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(_data(error: 'Data fetch failed')),
        );
      },
      build: () => ScreenSpecBloc(interpreter: mockInterpreter),
      act: (bloc) => bloc.add(const ScreenSpecLoadEvent(spec: _testSpec)),
      expect: () => [
        isA<ScreenSpecLoadingState>(),
        isA<ScreenSpecErrorState>().having(
          (s) => s.message,
          'message',
          'Data fetch failed',
        ),
      ],
    );

    blocTestSafe<ScreenSpecBloc, ScreenSpecState>(
      'emits multiple loaded states as data updates arrive',
      setUp: () {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.fromIterable([
            _data(),
            _data(),
          ]),
        );
      },
      build: () => ScreenSpecBloc(interpreter: mockInterpreter),
      act: (bloc) => bloc.add(const ScreenSpecLoadEvent(spec: _testSpec)),
      expect: () => [
        isA<ScreenSpecLoadingState>(),
        isA<ScreenSpecLoadedState>(),
        isA<ScreenSpecLoadedState>(),
      ],
    );
  });
}
