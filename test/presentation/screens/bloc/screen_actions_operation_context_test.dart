@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_domain/services.dart';
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

    // Needed if we use `any()` with non-nullable OperationContext.
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

  group('ScreenActionsBloc (TG-006)', () {
    late MockEntityActionService mockEntityActionService;
    late AppErrorReporter errorReporter;

    setUp(() {
      mockEntityActionService = MockEntityActionService();
      errorReporter = AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      );

      when(
        () => mockEntityActionService.completeTask(
          any(),
          occurrenceDate: any(named: 'occurrenceDate'),
          originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
    });

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'forwards OperationContext into EntityActionService.completeTask',
      build: () {
        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) async {
        bloc.add(
          ScreenActionsTaskCompletionChanged(
            taskId: 'task-1',
            completed: true,
            occurrenceDate: DateTime.utc(2025, 1, 15),
            originalOccurrenceDate: DateTime.utc(2025, 1, 1),
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => mockEntityActionService.completeTask(
                    'task-1',
                    occurrenceDate: any(named: 'occurrenceDate'),
                    originalOccurrenceDate: any(
                      named: 'originalOccurrenceDate',
                    ),
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);

        expect(captured!.correlationId, isNotEmpty);
        expect(captured.feature, 'screen_actions');
        expect(captured.screen, 'screen_actions');
        expect(captured.intent, 'task_completion_changed');
        expect(captured.operation, 'complete_occurrence');
        expect(captured.entityType, 'task');
        expect(captured.entityId, 'task-1');
        expect(captured.extraFields, contains('occurrenceDate'));
        expect(captured.extraFields, contains('originalOccurrenceDate'));
      },
    );
  });
}
