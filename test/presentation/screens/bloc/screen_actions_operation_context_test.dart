@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../../../helpers/bloc_test_patterns.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/repository_mocks.dart';

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
    late MockTaskRepositoryContract taskRepository;
    late MockProjectRepositoryContract projectRepository;
    late MockValueRepositoryContract valueRepository;
    late MockOccurrenceCommandService occurrenceCommandService;
    late TaskWriteService taskWriteService;
    late ProjectWriteService projectWriteService;
    late ValueWriteService valueWriteService;
    late AppErrorReporter errorReporter;

    setUp(() {
      taskRepository = MockTaskRepositoryContract();
      projectRepository = MockProjectRepositoryContract();
      valueRepository = MockValueRepositoryContract();
      occurrenceCommandService = MockOccurrenceCommandService();
      taskWriteService = TaskWriteService(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        occurrenceCommandService: occurrenceCommandService,
      );
      projectWriteService = ProjectWriteService(
        projectRepository: projectRepository,
        occurrenceCommandService: occurrenceCommandService,
      );
      valueWriteService = ValueWriteService(valueRepository: valueRepository);
      errorReporter = AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      );

      when(
        () => occurrenceCommandService.completeTask(
          taskId: any(named: 'taskId'),
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
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
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
                  () => occurrenceCommandService.completeTask(
                    taskId: 'task-1',
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
