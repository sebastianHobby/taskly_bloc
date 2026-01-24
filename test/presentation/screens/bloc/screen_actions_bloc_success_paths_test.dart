@Tags(['unit'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/services.dart';
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

    registerFallbackValue(EntityType.task);
    registerFallbackValue(EntityActionType.delete);
  });

  setUp(setUpTestEnvironment);

  group('ScreenActionsBloc success paths', () {
    late MockEntityActionService mockEntityActionService;
    late AppErrorReporter errorReporter;

    setUp(() {
      mockEntityActionService = MockEntityActionService();
      errorReporter = AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      );
    });

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'completes project occurrence when completed=true',
      build: () {
        when(
          () => mockEntityActionService.completeProject(
            any(),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.completeProject(
                    'project-1',
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
          () => mockEntityActionService.uncompleteProject(
            any(),
            occurrenceDate: any(named: 'occurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.uncompleteProject(
                    'project-1',
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
          () => mockEntityActionService.pinTask(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.pinTask(
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
          () => mockEntityActionService.completeTask(
            any(),
            occurrenceDate: any(named: 'occurrenceDate'),
            originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

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
        expect(captured!.operation, 'complete_occurrence');
        expect(captured.intent, 'task_completion_changed');
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'uncompletes task occurrence when completed=false',
      build: () {
        when(
          () => mockEntityActionService.uncompleteTask(
            any(),
            occurrenceDate: any(named: 'occurrenceDate'),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.uncompleteTask(
                    'task-1',
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
          () => mockEntityActionService.unpinTask(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.unpinTask(
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
          () => mockEntityActionService.pinProject(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.pinProject(
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
          () => mockEntityActionService.unpinProject(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.unpinProject(
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
      'deletes entity through EntityActionService.performAction',
      build: () {
        when(
          () => mockEntityActionService.performAction(
            entityId: any(named: 'entityId'),
            entityType: any(named: 'entityType'),
            action: any(named: 'action'),
            params: null,
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.performAction(
                    entityId: 'task-1',
                    entityType: EntityType.task,
                    action: EntityActionType.delete,
                    params: null,
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
          () => mockEntityActionService.moveTask(
            'task-1',
            null,
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
          () => mockEntityActionService.moveTask(
            'task-1',
            null,
            context: any(named: 'context'),
          ),
        ).called(1);
      },
    );

    blocTestSafe<ScreenActionsBloc, ScreenActionsState>(
      'moves task with a target project id',
      build: () {
        when(
          () => mockEntityActionService.moveTask(
            'task-1',
            'project-1',
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.moveTask(
                    'task-1',
                    'project-1',
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
          () => mockEntityActionService.completeTaskSeries(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.completeTaskSeries(
                    'task-1',
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
          () => mockEntityActionService.completeProjectSeries(
            any(),
            context: any(named: 'context'),
          ),
        ).thenAnswer((_) async {});

        return ScreenActionsBloc(
          entityActionService: mockEntityActionService,
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
                  () => mockEntityActionService.completeProjectSeries(
                    'p-1',
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
          entityActionService: mockEntityActionService,
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
