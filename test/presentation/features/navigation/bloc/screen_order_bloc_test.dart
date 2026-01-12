import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/screen_order_bloc.dart';

import '../../../../helpers/bloc_test_patterns.dart';
import '../../../../mocks/repository_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenOrderBloc', () {
    late MockScreenDefinitionsRepositoryContract mockRepository;
    late TestStreamController<List<ScreenWithPreferences>> screensController;

    // Test screens using real system screen definitions
    late ScreenWithPreferences testScreen1;
    late ScreenWithPreferences testScreen2;
    late ScreenWithPreferences testScreen3;

    setUpAll(() {
      registerFallbackValue(<String>[]);
    });

    setUp(() {
      mockRepository = MockScreenDefinitionsRepositoryContract();
      screensController = TestStreamController<List<ScreenWithPreferences>>();

      // Create test screens using real system screen definitions
      testScreen1 = ScreenWithPreferences(
        screen: SystemScreenDefinitions.myDay,
        preferences: const ScreenPreferences(sortOrder: 0),
      );

      testScreen2 = ScreenWithPreferences(
        screen: SystemScreenDefinitions.scheduled,
        preferences: const ScreenPreferences(sortOrder: 1),
      );

      testScreen3 = ScreenWithPreferences(
        screen: SystemScreenDefinitions.someday,
        preferences: const ScreenPreferences(sortOrder: 2),
      );

      when(() => mockRepository.watchAllScreens()).thenAnswer(
        (_) => screensController.stream,
      );
    });

    tearDown(() async {
      await screensController.close();
    });

    ScreenOrderBloc buildBloc() =>
        ScreenOrderBloc(screensRepository: mockRepository);

    test('initial state is loading', () {
      final bloc = buildBloc();
      expect(bloc.state.status, ScreenOrderStatus.loading);
      expect(bloc.state.screens, isEmpty);
      expect(bloc.state.error, isNull);
      bloc.close();
    });

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'emits ready state when screens stream emits',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ScreenOrderStarted());
        screensController.emit([testScreen1, testScreen2, testScreen3]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<ScreenOrderState>()
            .having((s) => s.status, 'status', ScreenOrderStatus.ready)
            .having((s) => s.screens.length, 'screens count', 3)
            .having(
              (s) => s.screens.first.screen.screenKey,
              'first key',
              'my_day',
            ),
      ],
      verify: (_) {
        verify(() => mockRepository.watchAllScreens()).called(1);
      },
    );

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'sorts screens by effectiveSortOrder',
      build: buildBloc,
      act: (bloc) {
        bloc.add(const ScreenOrderStarted());
        // Add screens in wrong order
        screensController.emit([testScreen3, testScreen1, testScreen2]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<ScreenOrderState>()
            .having((s) => s.status, 'status', ScreenOrderStatus.ready)
            .having(
              (s) => s.screens.map((s) => s.screen.screenKey).toList(),
              'ordered keys',
              ['my_day', 'scheduled', 'someday'],
            ),
      ],
    );

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'handles reorder moving item down',
      build: () {
        when(() => mockRepository.reorderScreens(any())).thenAnswer(
          (_) async {
            return;
          },
        );
        return buildBloc();
      },
      seed: () => ScreenOrderState.ready(
        screens: [testScreen1, testScreen2, testScreen3],
      ),
      act: (bloc) {
        // Move item 0 to position 2 (after removal adjustment)
        bloc.add(const ScreenOrderReordered(oldIndex: 0, newIndex: 2));
      },
      expect: () => [
        isA<ScreenOrderState>()
            .having((s) => s.status, 'status', ScreenOrderStatus.ready)
            .having(
              (s) => s.screens.map((s) => s.screen.screenKey).toList(),
              'reordered keys',
              ['scheduled', 'my_day', 'someday'],
            ),
      ],
      verify: (_) {
        verify(
          () => mockRepository.reorderScreens(
            ['scheduled', 'my_day', 'someday'],
          ),
        ).called(1);
      },
    );

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'handles reorder moving item up',
      build: () {
        when(() => mockRepository.reorderScreens(any())).thenAnswer(
          (_) async {
            return;
          },
        );
        return buildBloc();
      },
      seed: () => ScreenOrderState.ready(
        screens: [testScreen1, testScreen2, testScreen3],
      ),
      act: (bloc) {
        // Move item 2 to position 0
        bloc.add(const ScreenOrderReordered(oldIndex: 2, newIndex: 0));
      },
      expect: () => [
        isA<ScreenOrderState>()
            .having((s) => s.status, 'status', ScreenOrderStatus.ready)
            .having(
              (s) => s.screens.map((s) => s.screen.screenKey).toList(),
              'reordered keys',
              ['someday', 'my_day', 'scheduled'],
            ),
      ],
      verify: (_) {
        verify(
          () => mockRepository.reorderScreens(
            ['someday', 'my_day', 'scheduled'],
          ),
        ).called(1);
      },
    );

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'emits failure when reorder fails',
      build: () {
        when(() => mockRepository.reorderScreens(any())).thenThrow(
          Exception('Failed to save'),
        );
        return buildBloc();
      },
      seed: () => ScreenOrderState.ready(
        screens: [testScreen1, testScreen2, testScreen3],
      ),
      act: (bloc) {
        bloc.add(const ScreenOrderReordered(oldIndex: 0, newIndex: 2));
      },
      expect: () => [
        // First emits optimistic update
        isA<ScreenOrderState>().having(
          (s) => s.status,
          'status',
          ScreenOrderStatus.ready,
        ),
        // Then emits failure
        isA<ScreenOrderState>()
            .having((s) => s.status, 'status', ScreenOrderStatus.failure)
            .having((s) => s.error, 'has error', isNotNull),
      ],
    );

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'does nothing when reordering empty list',
      build: buildBloc,
      seed: () => const ScreenOrderState.ready(screens: []),
      act: (bloc) {
        bloc.add(const ScreenOrderReordered(oldIndex: 0, newIndex: 1));
      },
      expect: () => <ScreenOrderState>[],
      verify: (_) {
        verifyNever(() => mockRepository.reorderScreens(any()));
      },
    );

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'updates when screens stream emits new data',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ScreenOrderStarted());
        screensController.emit([testScreen1, testScreen2]);
        await Future<void>.delayed(const Duration(milliseconds: 1));
        // Simulate new screen added
        screensController.emit([testScreen1, testScreen2, testScreen3]);
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // First emission with 2 screens
        isA<ScreenOrderState>().having((s) => s.screens.length, 'count', 2),
        // Second emission with 3 screens
        isA<ScreenOrderState>().having((s) => s.screens.length, 'count', 3),
      ],
    );

    blocTestSafe<ScreenOrderBloc, ScreenOrderState>(
      'cancels previous subscription on restart',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ScreenOrderStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ScreenOrderStarted());
        screensController.emit([testScreen1]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<ScreenOrderState>().having((s) => s.screens.length, 'count', 1),
      ],
    );

    group('ScreenOrderState', () {
      test('loading constructor creates correct state', () {
        const state = ScreenOrderState.loading();
        expect(state.status, ScreenOrderStatus.loading);
        expect(state.screens, isEmpty);
        expect(state.error, isNull);
      });

      test('ready constructor creates correct state', () {
        final state = ScreenOrderState.ready(
          screens: [testScreen1, testScreen2],
        );
        expect(state.status, ScreenOrderStatus.ready);
        expect(state.screens.length, 2);
        expect(state.error, isNull);
      });

      test('failure constructor creates correct state', () {
        const state = ScreenOrderState.failure('Test error');
        expect(state.status, ScreenOrderStatus.failure);
        expect(state.screens, isEmpty);
        expect(state.error, 'Test error');
      });
    });
  });
}
