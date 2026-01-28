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

  group('ScreenActionsBloc success paths', () {
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
      'completes project occurrence when completed=true',
      build: () {
        when(
          () => occurrenceCommandService.completeProject(
            projectId: any(named: 'projectId'),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

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
            occurrenceDate: DateTime.utc(2025, 1, 15),
            originalOccurrenceDate: DateTime.utc(2025, 1, 1),
            completer: completer,
          ),
        );

        await completer.future;
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => occurrenceCommandService.completeProject(
                    projectId: 'project-1',
                    occurrenceDate: any(named: 'occurrenceDate'),
                    originalOccurrenceDate: any(
                      named: 'originalOccurrenceDate',
                    ),
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.feature, 'screen_actions');
        expect(captured.screen, 'screen_actions');
        expect(captured.intent, 'project_completion_changed');
        expect(captured.operation, 'complete_occurrence');
        expect(captured.entityType, EntityType.project.name);
        expect(captured.entityId, 'project-1');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'uncompletes project occurrence when completed=false',
      build: () {
        when(
          () => occurrenceCommandService.uncompleteProject(
            projectId: any(named: 'projectId'),
            occurrenceDate: any(named: 'occurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsProjectCompletionChanged(
            projectId: 'project-1',
            completed: false,
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => occurrenceCommandService.uncompleteProject(
                    projectId: 'project-1',
                    occurrenceDate: any(named: 'occurrenceDate'),
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.intent, 'project_completion_changed');
        expect(captured.operation, 'uncomplete_occurrence');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'pins task when pinned=true',
      build: () {
        when(
          () => allocationOrchestrator.pinTask(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsTaskPinnedChanged(
            taskId: 'task-1',
            pinned: true,
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => allocationOrchestrator.pinTask(
                    'task-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.intent, 'task_pinned_changed');
        expect(captured.operation, 'pin');
        expect(captured.extraFields['pinned'], true);
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'completes task occurrence when completed=true',
      build: () {
        when(
          () => occurrenceCommandService.completeTask(
            taskId: any(named: 'taskId'),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

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
        expect(captured!.operation, 'complete_occurrence');
        expect(captured.intent, 'task_completion_changed');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'uncompletes task occurrence when completed=false',
      build: () {
        when(
          () => occurrenceCommandService.uncompleteTask(
            taskId: any(named: 'taskId'),
            occurrenceDate: any(named: 'occurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

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
            completed: false,
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => occurrenceCommandService.uncompleteTask(
                    taskId: 'task-1',
                    occurrenceDate: any(named: 'occurrenceDate'),
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.operation, 'uncomplete_occurrence');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'unpins task when pinned=false',
      build: () {
        when(
          () => allocationOrchestrator.unpinTask(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsTaskPinnedChanged(
            taskId: 'task-1',
            pinned: false,
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => allocationOrchestrator.unpinTask(
                    'task-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.operation, 'unpin');
        expect(captured.extraFields['pinned'], false);
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'pins project when pinned=true',
      build: () {
        when(
          () => allocationOrchestrator.pinProject(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsProjectPinnedChanged(
            projectId: 'project-1',
            pinned: true,
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => allocationOrchestrator.pinProject(
                    'project-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.operation, 'pin');
        expect(captured.intent, 'project_pinned_changed');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'unpins project when pinned=false',
      build: () {
        when(
          () => allocationOrchestrator.unpinProject(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsProjectPinnedChanged(
            projectId: 'project-1',
            pinned: false,
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => allocationOrchestrator.unpinProject(
                    'project-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.operation, 'unpin');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'deletes entity through TaskWriteService.delete',
      build: () {
        when(
          () => taskRepository.delete(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsDeleteEntity(
            entityType: EntityType.task,
            entityId: 'task-1',
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => taskRepository.delete(
                    'task-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.intent, 'delete_entity');
        expect(captured.operation, 'delete');
        expect(captured.entityType, EntityType.task.name);
        expect(captured.entityId, 'task-1');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'moves task with empty targetProjectId as null',
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
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsMoveTaskToProject(
            taskId: 'task-1',
            targetProjectId: '',
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        verify(
          () => taskRepository.update(
            id: 'task-1',
            name: any(named: 'name'),
            completed: any(named: 'completed'),
            description: any(named: 'description'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: null,
            priority: any(named: 'priority'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            seriesEnded: any(named: 'seriesEnded'),
            valueIds: any(named: 'valueIds'),
            context: any(named: 'context'),
          ),
        ).called(1);
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'moves task with a target project id',
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
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsMoveTaskToProject(
            taskId: 'task-1',
            targetProjectId: 'project-1',
          ),
        );
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => taskRepository.update(
                    id: 'task-1',
                    name: any(named: 'name'),
                    completed: any(named: 'completed'),
                    description: any(named: 'description'),
                    startDate: any(named: 'startDate'),
                    deadlineDate: any(named: 'deadlineDate'),
                    projectId: 'project-1',
                    priority: any(named: 'priority'),
                    repeatIcalRrule: any(named: 'repeatIcalRrule'),
                    repeatFromCompletion: any(named: 'repeatFromCompletion'),
                    seriesEnded: any(named: 'seriesEnded'),
                    valueIds: any(named: 'valueIds'),
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.extraFields['targetProjectId'], 'project-1');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'completes task series',
      build: () {
        when(
          () => occurrenceCommandService.completeTaskSeries(
            taskId: any(named: 'taskId'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(const ScreenActionsTaskSeriesCompleted(taskId: 'task-1'));
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => occurrenceCommandService.completeTaskSeries(
                    taskId: 'task-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.intent, 'task_complete_series');
        expect(captured.operation, 'complete_series');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'completes project series',
      build: () {
        when(
          () => occurrenceCommandService.completeProjectSeries(
            projectId: any(named: 'projectId'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(const ScreenActionsProjectSeriesCompleted(projectId: 'p-1'));
      },
      expect: () => const <dynamic>[],
      verify: (bloc) {
        final captured =
            verify(
                  () => occurrenceCommandService.completeProjectSeries(
                    projectId: 'p-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expect(captured, isNotNull);
        expect(captured!.intent, 'project_complete_series');
        expect(captured.operation, 'complete_series');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'FailureEvent emits failure then idle',
      build: () {
        return ScreenActionsBloc(
          taskWriteService: taskWriteService,
          projectWriteService: projectWriteService,
          valueWriteService: valueWriteService,
          errorReporter: errorReporter,
        );
      },
      act: (bloc) {
        bloc.add(
          const ScreenActionsFailureEvent(
            failureKind: ScreenActionsFailureKind.invalidOccurrenceData,
            fallbackMessage: 'Bad dates',
            entityType: EntityType.task,
            entityId: 'task-1',
          ),
        );
      },
      expect: () => <dynamic>[
        isA<ScreenActionsFailureState>(),
        isA<ScreenActionsIdleState>(),
      ],
    );
  });
}
