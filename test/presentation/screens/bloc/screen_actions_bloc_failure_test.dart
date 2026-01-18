@Tags(['unit'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../../../helpers/bloc_test_patterns.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/test_imports.dart';

class MockEntityActionService extends Mock implements EntityActionService {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();

    registerFallbackValue(
      OperationContext(
        correlationId: 'fallback-correlation-id',
        feature: 'fallback-feature',
        intent: 'fallback-intent',
        operation: 'fallback-operation',
      ),
    );
  });

  setUp(setUpTestEnvironment);

  group('ScreenActionsBloc failure handling', () {
    late MockEntityActionService mockEntityActionService;
    late AppErrorReporter errorReporter;

    setUp(() {
      mockEntityActionService = MockEntityActionService();
      errorReporter = AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      );
    });

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'emits failure then idle and completes completer on expected failure',
      build: () {
        when(
          () => mockEntityActionService.completeTask(
            any(),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenThrow(
          const InputValidationFailure(message: 'bad input'),
        );

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) async {
        final completer = Completer<void>();

        bloc.add(
          ScreenActionsTaskCompletionChanged(
            taskId: 'task-1',
            completed: true,
            occurrenceDate: DateTime.utc(2025, 1, 15),
            originalOccurrenceDate: DateTime.utc(2025, 1, 1),
            completer: completer,
          ),
        );

        await expectLater(
          completer.future,
          throwsA(isA<InputValidationFailure>()),
        );
      },
      expect: () => <dynamic>[
        isA<ScreenActionsFailureState>()
            .having(
              (s) => s.failureKind,
              'failureKind',
              ScreenActionsFailureKind.completionFailed,
            )
            .having(
              (s) => s.shouldShowSnackBar,
              'shouldShowSnackBar',
              true,
            )
            .having((s) => s.entityType, 'entityType', EntityType.task)
            .having((s) => s.entityId, 'entityId', 'task-1'),
        isA<ScreenActionsIdleState>(),
      ],
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'emits failure then idle and suppresses snackbar on unexpected failure',
      build: () {
        when(
          () => mockEntityActionService.completeTask(
            any(),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenThrow(
          const UnknownFailure(message: 'boom'),
        );

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsTaskCompletionChanged(
            taskId: 'task-1',
            completed: true,
          ),
        );
      },
      expect: () => <dynamic>[
        isA<ScreenActionsFailureState>().having(
          (s) => s.shouldShowSnackBar,
          'shouldShowSnackBar',
          false,
        ),
        isA<ScreenActionsIdleState>(),
      ],
    );
  });
}
