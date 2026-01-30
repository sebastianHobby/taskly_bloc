@Tags(['unit', 'scheduled'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

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

  late MockTaskRepositoryContract taskRepository;
  late TaskWriteService taskWriteService;
  late MockProjectRepositoryContract projectRepository;
  late MockAllocationOrchestrator allocationOrchestrator;
  late MockOccurrenceCommandService occurrenceCommandService;
  late ProjectWriteService projectWriteService;
  late DemoModeService demoModeService;

  ScheduledScreenBloc buildBloc() {
    return ScheduledScreenBloc(
      taskWriteService: taskWriteService,
      projectWriteService: projectWriteService,
      demoModeService: demoModeService,
    );
  }

  setUp(() {
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
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
    demoModeService = DemoModeService();

    when(
      () => taskRepository.bulkRescheduleDeadlines(
        taskIds: any(named: 'taskIds'),
        deadlineDate: any(named: 'deadlineDate'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => 2);
    when(
      () => projectRepository.bulkRescheduleDeadlines(
        projectIds: any(named: 'projectIds'),
        deadlineDate: any(named: 'deadlineDate'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => 1);

    addTearDown(demoModeService.dispose);
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
          .having(
            (s) => s.effect,
            'effect',
            isA<ScheduledBulkDeadlineRescheduled>(),
          )
          .having(
            (s) => (s.effect as ScheduledBulkDeadlineRescheduled).taskCount,
            'taskCount',
            2,
          ),
    ],
    verify: (_) {
      final captured = verify(
        () => taskRepository.bulkRescheduleDeadlines(
          taskIds: any(named: 'taskIds'),
          deadlineDate: any(named: 'deadlineDate'),
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
          .having(
            (s) => s.effect,
            'effect',
            isA<ScheduledBulkDeadlineRescheduled>(),
          )
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
        () => taskRepository.bulkRescheduleDeadlines(
          taskIds: any(named: 'taskIds'),
          deadlineDate: any(named: 'deadlineDate'),
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
        isA<ScheduledShowMessage>().having(
          (e) => e.message,
          'message',
          contains('boom'),
        ),
      ),
    ],
  );
}
