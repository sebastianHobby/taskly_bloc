@Tags(['unit'])
library;

import 'dart:async';

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
    late MockTaskRepositoryContract taskRepository;
    late MockProjectRepositoryContract projectRepository;
    late MockValueRepositoryContract valueRepository;
    late MockAllocationOrchestrator allocationOrchestrator;
    late MockOccurrenceCommandService occurrenceCommandService;
    late TaskWriteService taskWriteService;
    late ProjectWriteService projectWriteService;
    late ValueWriteService valueWriteService;
    late AppErrorReporter errorReporter;

    setUp(() {
      taskRepository = MockTaskRepositoryContract();
      projectRepository = MockProjectRepositoryContract();
      valueRepository = MockValueRepositoryContract();
      allocationOrchestrator = MockAllocationOrchestrator();
      occurrenceCommandService = MockOccurrenceCommandService();
      taskWriteService = TaskWriteService(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        allocationOrchestrator: allocationOrchestrator,
        occurrenceCommandService: occurrenceCommandService,
      );
      projectWriteService = ProjectWriteService(
        projectRepository: projectRepository,
        allocationOrchestrator: allocationOrchestrator,
        occurrenceCommandService: occurrenceCommandService,
      );
      valueWriteService = ValueWriteService(valueRepository: valueRepository);
      errorReporter = AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      );
    });

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'emits failure then idle and completes completer on expected failure',
      build: () {
        when(
          () => occurrenceCommandService.completeTask(
            taskId: any(named: 'taskId'),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenThrow(
          const InputValidationFailure(message: 'bad input'),
        );

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
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
          () => occurrenceCommandService.completeTask(
            taskId: any(named: 'taskId'),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenThrow(
          const UnknownFailure(message: 'boom'),
        );

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
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

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'emits failure for project completion errors',
      build: () {
        when(
          () => occurrenceCommandService.completeProject(
            projectId: any(named: 'projectId'),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenThrow(
          const InputValidationFailure(message: 'bad project'),
        );

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) async {
        final completer = Completer<void>();

        bloc.add(
          ScreenActionsProjectCompletionChanged(
            projectId: 'project-1',
            completed: true,
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
              (s) => s.entityType,
              'entityType',
              EntityType.project,
            )
            .having((s) => s.entityId, 'entityId', 'project-1'),
        isA<ScreenActionsIdleState>(),
      ],
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'emits failure for move task errors',
      build: () {
        when(
          () => taskRepository.getById('task-1'),
        ).thenAnswer((_) async => TestData.task(id: 'task-1'));
        when(
          () => taskRepository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            priority: any(named: 'priority'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            seriesEnded: any(named: 'seriesEnded'),
            valueIds: any(named: 'valueIds'),
            context: any(named: 'context'),
          ),
        ).thenThrow(
          const UnknownFailure(message: 'move failed'),
        );

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) async {
        final completer = Completer<void>();

        bloc.add(
          ScreenActionsMoveTaskToProject(
            taskId: 'task-1',
            targetProjectId: 'project-1',
            completer: completer,
          ),
        );

        await expectLater(
          completer.future,
          throwsA(isA<UnknownFailure>()),
        );
      },
      expect: () => <dynamic>[
        isA<ScreenActionsFailureState>()
            .having(
              (s) => s.failureKind,
              'failureKind',
              ScreenActionsFailureKind.moveFailed,
            )
            .having((s) => s.entityId, 'entityId', 'task-1'),
        isA<ScreenActionsIdleState>(),
      ],
    );
  });
}
