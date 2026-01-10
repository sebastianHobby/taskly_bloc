/// Tests for ScreenDefinitionBloc.
///
/// This BLoC is responsible for loading a single screen definition
/// by screenKey and handling:
/// - Initial loading state
/// - Successful screen load
/// - Screen not found (immediate, no grace period)
/// - Stream errors
/// - Screen deletion detection
///
/// Note: Grace period was removed in favor of proper synchronization.
/// AuthBloc now guarantees seeding is complete before emitting authenticated,
/// so ScreenDefinitionBloc can assume data exists if queried.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_definition_bloc.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/bloc_test_patterns.dart';
import '../../../../helpers/fallback_values.dart';
import '../../../../mocks/repository_mocks.dart';

void main() {
  group('ScreenDefinitionBloc', () {
    late MockScreenDefinitionsRepositoryContract mockRepository;
    late ScreenDefinitionBloc bloc;

    setUpAll(registerAllFallbackValues);

    setUp(() {
      mockRepository = MockScreenDefinitionsRepositoryContract();
    });

    tearDown(() async {
      await bloc.close();
    });

    ScreenDefinitionBloc buildBloc() =>
        bloc = ScreenDefinitionBloc(repository: mockRepository);

    // ═══════════════════════════════════════════════════════════════════════
    // Initial State
    // ═══════════════════════════════════════════════════════════════════════

    test('initial state is loading', () {
      bloc = buildBloc();
      expect(bloc.state, const ScreenDefinitionState.loading());
    });

    // ═══════════════════════════════════════════════════════════════════════
    // Successful Screen Load
    // ═══════════════════════════════════════════════════════════════════════

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'emits [loading, loaded] when screen found immediately',
      build: () {
        final screen = SystemScreenDefinitions.myDay;
        when(() => mockRepository.watchScreen('my_day')).thenAnswer(
          (_) => Stream.value(
            ScreenWithPreferences(
              screen: screen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const ScreenDefinitionEvent.subscriptionRequested(screenKey: 'my_day'),
      ),
      expect: () => [
        const ScreenDefinitionState.loading(),
        isA<ScreenDefinitionState>().having(
          (s) =>
              s.maybeMap(loaded: (l) => l.screen.screenKey, orElse: () => ''),
          'screen.screenKey',
          'my_day',
        ),
      ],
    );

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'emits loaded with correct screen data',
      build: () {
        final screen = TestData.screenDefinition(
          screenKey: 'custom-screen',
          name: 'My Custom Screen',
        );
        when(() => mockRepository.watchScreen('custom-screen')).thenAnswer(
          (_) => Stream.value(
            ScreenWithPreferences(
              screen: screen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 5,
              ),
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const ScreenDefinitionEvent.subscriptionRequested(
          screenKey: 'custom-screen',
        ),
      ),
      expect: () => [
        const ScreenDefinitionState.loading(),
        isA<ScreenDefinitionState>().having(
          (s) => s.maybeMap(loaded: (l) => l.screen.name, orElse: () => ''),
          'screen.name',
          'My Custom Screen',
        ),
      ],
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Not Found Handling (immediate - no grace period)
    // ═══════════════════════════════════════════════════════════════════════

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'emits notFound immediately when screen does not exist',
      build: () {
        when(() => mockRepository.watchScreen('unknown')).thenAnswer(
          (_) => Stream.value(null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const ScreenDefinitionEvent.subscriptionRequested(screenKey: 'unknown'),
      ),
      expect: () => [
        const ScreenDefinitionState.loading(),
        const ScreenDefinitionState.notFound(),
      ],
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Error Handling
    // ═══════════════════════════════════════════════════════════════════════

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'emits error when stream throws',
      build: () {
        when(() => mockRepository.watchScreen('error-screen')).thenAnswer(
          (_) => Stream.error(Exception('Database error'), StackTrace.current),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const ScreenDefinitionEvent.subscriptionRequested(
          screenKey: 'error-screen',
        ),
      ),
      expect: () => [
        const ScreenDefinitionState.loading(),
        isA<ScreenDefinitionState>().having(
          (s) => s.maybeMap(error: (_) => true, orElse: () => false),
          'is error state',
          true,
        ),
      ],
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Screen Deletion Detection
    // ═══════════════════════════════════════════════════════════════════════

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'emits notFound when previously loaded screen is deleted',
      build: () {
        final screen = TestData.screenDefinition(screenKey: 'deletable');
        final controller = TestStreamController<ScreenWithPreferences?>();

        when(() => mockRepository.watchScreen('deletable')).thenAnswer(
          (_) => controller.stream,
        );

        // Emit screen first, then null (simulating deletion)
        Future.delayed(const Duration(milliseconds: 100), () {
          controller.emit(
            ScreenWithPreferences(
              screen: screen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            ),
          );
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          controller.emit(null); // Simulate deletion
        });

        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const ScreenDefinitionEvent.subscriptionRequested(
          screenKey: 'deletable',
        ),
      ),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const ScreenDefinitionState.loading(),
        isA<ScreenDefinitionState>().having(
          (s) => s.maybeMap(loaded: (_) => true, orElse: () => false),
          'is loaded state',
          true,
        ),
        const ScreenDefinitionState.notFound(),
      ],
    );

    // ═══════════════════════════════════════════════════════════════════════
    // Stream Updates
    // ═══════════════════════════════════════════════════════════════════════

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'updates state when screen data changes',
      build: () {
        final screen1 = TestData.screenDefinition(
          screenKey: 'editable',
          name: 'Original Name',
        );
        final screen2 = TestData.screenDefinition(
          screenKey: 'editable',
          name: 'Updated Name',
        );
        final controller = TestStreamController<ScreenWithPreferences?>();

        when(() => mockRepository.watchScreen('editable')).thenAnswer(
          (_) => controller.stream,
        );

        // Emit original, then updated
        Future.delayed(const Duration(milliseconds: 100), () {
          controller.emit(
            ScreenWithPreferences(
              screen: screen1,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            ),
          );
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          controller.emit(
            ScreenWithPreferences(
              screen: screen2,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            ),
          );
        });

        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const ScreenDefinitionEvent.subscriptionRequested(
          screenKey: 'editable',
        ),
      ),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const ScreenDefinitionState.loading(),
        isA<ScreenDefinitionState>().having(
          (s) => s.maybeMap(loaded: (l) => l.screen.name, orElse: () => ''),
          'screen.name',
          'Original Name',
        ),
        isA<ScreenDefinitionState>().having(
          (s) => s.maybeMap(loaded: (l) => l.screen.name, orElse: () => ''),
          'screen.name',
          'Updated Name',
        ),
      ],
    );

    // ═══════════════════════════════════════════════════════════════════════
    // All System Screens Contract
    // ═══════════════════════════════════════════════════════════════════════

    group('system screen contracts', () {
      for (final systemScreen in SystemScreenDefinitions.all) {
        test('loads ${systemScreen.screenKey} correctly', () async {
          when(
            () => mockRepository.watchScreen(systemScreen.screenKey),
          ).thenAnswer(
            (_) => Stream.value(
              ScreenWithPreferences(
                screen: systemScreen,
                preferences: const ScreenPreferences(
                  isActive: true,
                  sortOrder: 0,
                ),
              ),
            ),
          );

          bloc = buildBloc();
          bloc.add(
            ScreenDefinitionEvent.subscriptionRequested(
              screenKey: systemScreen.screenKey,
            ),
          );

          // Wait for state to update
          await Future<void>.delayed(const Duration(milliseconds: 300));

          expect(
            bloc.state,
            isA<ScreenDefinitionState>().having(
              (s) => s.maybeMap(
                loaded: (l) => l.screen.screenKey,
                orElse: () => '',
              ),
              'screen.screenKey',
              systemScreen.screenKey,
            ),
          );
        });
      }
    });
  });
}
