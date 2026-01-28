@Tags(['unit', 'scheduled'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

class MockProjectWriteService extends Mock implements ProjectWriteService {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      const OperationContext(
        correlationId: 'corr-1',
        feature: 'scheduled',
        intent: 'test',
        operation: 'test',
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockTaskWriteService taskWriteService;
  late MockProjectWriteService projectWriteService;

  ScheduledScreenBloc buildBloc() {
    return ScheduledScreenBloc(
      taskWriteService: taskWriteService,
      projectWriteService: projectWriteService,
    );
  }

  setUp(() {
    taskWriteService = MockTaskWriteService();
    projectWriteService = MockProjectWriteService();

    when(
      () => taskWriteService.bulkRescheduleDeadlines(
        any(),
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => 2);
    when(
      () => projectWriteService.bulkRescheduleDeadlines(
        any(),
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => 1);
  });

  blocTestSafe<ScheduledScreenBloc, ScheduledScreenState>(
    'emits create task effect for selected day',
    build: buildBloc,
    act: (bloc) => bloc.add(
      ScheduledCreateTaskForDayRequested(day: DateTime(2025, 1, 10)),
    ),
    expect: () => [
      isA<ScheduledScreenReady>().having(
        (s) => s.effect,
        'effect',
        isA<ScheduledOpenTaskNew>().having(
          (e) => e.defaultDeadlineDay,
          'defaultDeadlineDay',
          DateTime(2025, 1, 10),
        ),
      ),
    ],
  );

  blocTestSafe<ScheduledScreenBloc, ScheduledScreenState>(
    'reschedules tasks and emits bulk effect',
    build: buildBloc,
    act: (bloc) => bloc.add(
      ScheduledRescheduleTasksDeadlineRequested(
        taskIds: ['t1', 't2'],
        newDeadlineDay: DateTime(2025, 1, 20),
      ),
    ),
    expect: () => [
      isA<ScheduledScreenReady>()
          .having((s) => s.effect, 'effect', isA<ScheduledBulkDeadlineRescheduled>())
          .having(
            (s) => (s.effect as ScheduledBulkDeadlineRescheduled).taskCount,
            'taskCount',
            2,
          ),
    ],
    verify: (_) {
      final captured = verify(
        () => taskWriteService.bulkRescheduleDeadlines(
          any(),
          any(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.feature, 'scheduled');
      expect(ctx.operation, 'task_update_deadline');
    },
  );

  blocTestSafe<ScheduledScreenBloc, ScheduledScreenState>(
    'reschedules projects and emits bulk effect',
    build: buildBloc,
    act: (bloc) => bloc.add(
      ScheduledRescheduleProjectsDeadlineRequested(
        projectIds: ['p1'],
        newDeadlineDay: DateTime(2025, 2, 1),
      ),
    ),
    expect: () => [
      isA<ScheduledScreenReady>()
          .having((s) => s.effect, 'effect', isA<ScheduledBulkDeadlineRescheduled>())
          .having(
            (s) => (s.effect as ScheduledBulkDeadlineRescheduled).projectCount,
            'projectCount',
            1,
          ),
    ],
  );

  blocTestSafe<ScheduledScreenBloc, ScheduledScreenState>(
    'emits show message on reschedule failure',
    build: () {
      when(
        () => taskWriteService.bulkRescheduleDeadlines(
          any(),
          any(),
          context: any(named: 'context'),
        ),
      ).thenThrow(StateError('boom'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      ScheduledRescheduleTasksDeadlineRequested(
        taskIds: ['t1'],
        newDeadlineDay: DateTime(2025, 3, 1),
      ),
    ),
    expect: () => [
      isA<ScheduledScreenReady>().having(
        (s) => s.effect,
        'effect',
        isA<ScheduledShowMessage>().having((e) => e.message, 'message', contains('boom')),
      ),
    ],
  );
}

