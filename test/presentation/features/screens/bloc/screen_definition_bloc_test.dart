/// Legacy tests for the removed `ScreenDefinitionBloc`.
///
/// The app has hard-cut over to the `ScreenSpec` unified-screen pipeline.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy ScreenDefinitionBloc tests retired', () {
    // Intentionally empty.
  });
}

/*
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

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // Screen Deletion Detection
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'emits notFound when previously loaded screen is deleted',
      build: () {
        final screen = ScreenSpec(
          id: 'deletable-id',
          screenKey: 'deletable',
          name: 'Deletable',
          template: const ScreenTemplateSpec.standardScaffoldV1(),
        );
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

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // Stream Updates
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    blocTestSafe<ScreenDefinitionBloc, ScreenDefinitionState>(
      'updates state when screen data changes',
      build: () {
        final screen1 = ScreenSpec(
          id: 'editable-id',
          screenKey: 'editable',
          name: 'Original Name',
          template: const ScreenTemplateSpec.standardScaffoldV1(),
        );
        final screen2 = ScreenSpec(
          id: 'editable-id',
          screenKey: 'editable',
          name: 'Updated Name',
          template: const ScreenTemplateSpec.standardScaffoldV1(),
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

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // All System Screens Contract
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    group('system screen contracts', () {
      for (final systemScreen in SystemScreenSpecs.all) {
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

*/
