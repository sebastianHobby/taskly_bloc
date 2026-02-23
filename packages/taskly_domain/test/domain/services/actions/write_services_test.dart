@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

import '../../../helpers/test_imports.dart';

class _MockTaskRepository extends Mock implements TaskRepositoryContract {}

class _MockProjectRepository extends Mock
    implements ProjectRepositoryContract {}

class _MockRoutineRepository extends Mock
    implements RoutineRepositoryContract {}

class _MockValueRepository extends Mock implements ValueRepositoryContract {}

class _MockOccurrenceCommandService extends Mock
    implements OccurrenceCommandService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const OperationContext(
        correlationId: 'c1',
        feature: 'test',
        intent: 'test',
        operation: 'test.op',
      ),
    );
    registerFallbackValue(TaskReminderKind.none);
    registerFallbackValue(RoutinePeriodType.day);
    registerFallbackValue(RoutineScheduleMode.flexible);
    registerFallbackValue(RoutineSkipPeriodType.week);
    registerFallbackValue(ValuePriority.medium);
  });

  group('TaskWriteService', () {
    late _MockTaskRepository taskRepository;
    late _MockProjectRepository projectRepository;
    late _MockOccurrenceCommandService occurrenceCommandService;
    late TaskWriteService service;
    final context = const OperationContext(
      correlationId: 'ctx-task',
      feature: 'test',
      intent: 'task',
      operation: 'task.op',
    );

    setUp(() {
      taskRepository = _MockTaskRepository();
      projectRepository = _MockProjectRepository();
      occurrenceCommandService = _MockOccurrenceCommandService();
      service = TaskWriteService(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        occurrenceCommandService: occurrenceCommandService,
      );
    });

    testSafe('create/update return success with valid commands', () async {
      when(
        () => taskRepository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          priority: any(named: 'priority'),
          reminderKind: any(named: 'reminderKind'),
          reminderAtUtc: any(named: 'reminderAtUtc'),
          reminderMinutesBeforeDue: any(named: 'reminderMinutesBeforeDue'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          checklistTitles: any(named: 'checklistTitles'),
          context: context,
        ),
      ).thenAnswer((_) async {});
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
          reminderKind: any(named: 'reminderKind'),
          reminderAtUtc: any(named: 'reminderAtUtc'),
          reminderMinutesBeforeDue: any(named: 'reminderMinutesBeforeDue'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          isPinned: any(named: 'isPinned'),
          checklistTitles: any(named: 'checklistTitles'),
          context: context,
        ),
      ).thenAnswer((_) async {});

      const createCommand = CreateTaskCommand(name: 'Task', completed: false);
      const updateCommand = UpdateTaskCommand(
        id: 't1',
        name: 'Task',
        completed: false,
      );

      final createResult = await service.create(
        createCommand,
        context: context,
      );
      final updateResult = await service.update(
        updateCommand,
        context: context,
      );

      expect(createResult, isA<CommandSuccess>());
      expect(updateResult, isA<CommandSuccess>());
    });

    testSafe(
      'delegates delete/complete/uncomplete/series operations',
      () async {
        when(
          () => taskRepository.delete('t1', context: context),
        ).thenAnswer((_) async {});
        when(
          () => occurrenceCommandService.completeTask(
            taskId: 't1',
            occurrenceDate: null,
            originalOccurrenceDate: null,
            context: context,
          ),
        ).thenAnswer((_) async {});
        when(
          () => occurrenceCommandService.uncompleteTask(
            taskId: 't1',
            occurrenceDate: null,
            context: context,
          ),
        ).thenAnswer((_) async {});
        when(
          () => occurrenceCommandService.completeTaskSeries(
            taskId: 't1',
            context: context,
          ),
        ).thenAnswer((_) async {});

        await service.delete('t1', context: context);
        await service.complete('t1', context: context);
        await service.uncomplete('t1', context: context);
        await service.completeSeries('t1', context: context);

        verify(() => taskRepository.delete('t1', context: context)).called(1);
        verify(
          () => occurrenceCommandService.completeTask(
            taskId: 't1',
            occurrenceDate: null,
            originalOccurrenceDate: null,
            context: context,
          ),
        ).called(1);
        verify(
          () => occurrenceCommandService.uncompleteTask(
            taskId: 't1',
            occurrenceDate: null,
            context: context,
          ),
        ).called(1);
        verify(
          () => occurrenceCommandService.completeTaskSeries(
            taskId: 't1',
            context: context,
          ),
        ).called(1);
      },
    );

    testSafe('move no-ops when task missing and updates when found', () async {
      when(
        () => taskRepository.getById('missing'),
      ).thenAnswer((_) async => null);
      await service.move('missing', 'p2', context: context);
      verifyNever(
        () => taskRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          context: any(named: 'context'),
        ),
      );

      final task = Task(
        id: 't1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        name: 'Task',
        completed: false,
        projectId: 'p1',
      );
      when(() => taskRepository.getById('t1')).thenAnswer((_) async => task);
      when(
        () => taskRepository.update(
          id: task.id,
          name: task.name,
          description: task.description,
          completed: task.completed,
          projectId: 'p2',
          startDate: task.startDate,
          deadlineDate: task.deadlineDate,
          priority: task.priority,
          repeatIcalRrule: task.repeatIcalRrule,
          repeatFromCompletion: task.repeatFromCompletion,
          context: context,
        ),
      ).thenAnswer((_) async {});

      await service.move('t1', 'p2', context: context);

      verify(() => taskRepository.getById('t1')).called(1);
      verify(
        () => taskRepository.update(
          id: task.id,
          name: task.name,
          description: task.description,
          completed: task.completed,
          projectId: 'p2',
          startDate: task.startDate,
          deadlineDate: task.deadlineDate,
          priority: task.priority,
          repeatIcalRrule: task.repeatIcalRrule,
          repeatFromCompletion: task.repeatFromCompletion,
          context: context,
        ),
      ).called(1);
    });

    testSafe('delegates bulk reschedule and snooze setters', () async {
      when(
        () => taskRepository.bulkRescheduleDeadlines(
          taskIds: ['t1', 't2'],
          deadlineDate: DateTime.utc(2026, 2, 1),
          context: context,
        ),
      ).thenAnswer((_) async => 2);
      when(
        () => taskRepository.bulkRescheduleStarts(
          taskIds: ['t1', 't2'],
          startDate: DateTime.utc(2026, 1, 25),
          context: context,
        ),
      ).thenAnswer((_) async => 2);
      when(
        () => taskRepository.setMyDaySnoozedUntil(
          id: 't1',
          untilUtc: DateTime.utc(2026, 1, 30),
          context: context,
        ),
      ).thenAnswer((_) async {});

      final a = await service.bulkRescheduleDeadlines(
        ['t1', 't2'],
        DateTime.utc(2026, 2, 1),
        context: context,
      );
      final b = await service.bulkRescheduleStarts(
        ['t1', 't2'],
        DateTime.utc(2026, 1, 25),
        context: context,
      );
      await service.setMyDaySnoozedUntil(
        't1',
        untilUtc: DateTime.utc(2026, 1, 30),
        context: context,
      );

      expect(a, 2);
      expect(b, 2);
    });
  });

  group('ProjectWriteService', () {
    late _MockProjectRepository repository;
    late _MockOccurrenceCommandService occurrenceService;
    late ProjectWriteService service;
    final context = const OperationContext(
      correlationId: 'ctx-project',
      feature: 'test',
      intent: 'project',
      operation: 'project.op',
    );

    setUp(() {
      repository = _MockProjectRepository();
      occurrenceService = _MockOccurrenceCommandService();
      service = ProjectWriteService(
        projectRepository: repository,
        occurrenceCommandService: occurrenceService,
      );
    });

    testSafe('create/update and delete delegate as expected', () async {
      when(
        () => repository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          priority: any(named: 'priority'),
          context: context,
        ),
      ).thenAnswer((_) async {});
      when(
        () => repository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          priority: any(named: 'priority'),
          isPinned: any(named: 'isPinned'),
          context: context,
        ),
      ).thenAnswer((_) async {});
      when(
        () => repository.delete('p1', context: context),
      ).thenAnswer((_) async {});

      final createResult = await service.create(
        const CreateProjectCommand(
          name: 'Project',
          completed: false,
          valueIds: ['v1'],
        ),
        context: context,
      );
      final updateResult = await service.update(
        const UpdateProjectCommand(
          id: 'p1',
          name: 'Project',
          completed: false,
          valueIds: ['v1'],
        ),
        context: context,
      );
      await service.delete('p1', context: context);

      expect(createResult, isA<CommandSuccess>());
      expect(updateResult, isA<CommandSuccess>());
      verify(() => repository.delete('p1', context: context)).called(1);
    });

    testSafe('delegates occurrence and bulk methods', () async {
      when(
        () => occurrenceService.completeProject(
          projectId: 'p1',
          occurrenceDate: null,
          originalOccurrenceDate: null,
          context: context,
        ),
      ).thenAnswer((_) async {});
      when(
        () => occurrenceService.uncompleteProject(
          projectId: 'p1',
          occurrenceDate: null,
          context: context,
        ),
      ).thenAnswer((_) async {});
      when(
        () => occurrenceService.completeProjectSeries(
          projectId: 'p1',
          context: context,
        ),
      ).thenAnswer((_) async {});
      when(
        () => repository.bulkRescheduleDeadlines(
          projectIds: ['p1', 'p2'],
          deadlineDate: DateTime.utc(2026, 2, 1),
          context: context,
        ),
      ).thenAnswer((_) async => 2);

      await service.complete('p1', context: context);
      await service.uncomplete('p1', context: context);
      await service.completeSeries('p1', context: context);
      final count = await service.bulkRescheduleDeadlines(
        ['p1', 'p2'],
        DateTime.utc(2026, 2, 1),
        context: context,
      );

      expect(count, 2);
    });
  });

  group('RoutineWriteService', () {
    late _MockRoutineRepository repository;
    late RoutineWriteService service;
    final context = const OperationContext(
      correlationId: 'ctx-routine',
      feature: 'test',
      intent: 'routine',
      operation: 'routine.op',
    );

    setUp(() {
      repository = _MockRoutineRepository();
      service = RoutineWriteService(routineRepository: repository);
    });

    testSafe(
      'create/update/delete and completion mutations delegate',
      () async {
        when(
          () => repository.create(
            name: any(named: 'name'),
            projectId: any(named: 'projectId'),
            periodType: any(named: 'periodType'),
            scheduleMode: any(named: 'scheduleMode'),
            targetCount: any(named: 'targetCount'),
            scheduleDays: any(named: 'scheduleDays'),
            scheduleMonthDays: any(named: 'scheduleMonthDays'),
            scheduleTimeMinutes: any(named: 'scheduleTimeMinutes'),
            minSpacingDays: any(named: 'minSpacingDays'),
            restDayBuffer: any(named: 'restDayBuffer'),
            isActive: any(named: 'isActive'),
            pausedUntilUtc: any(named: 'pausedUntilUtc'),
            checklistTitles: any(named: 'checklistTitles'),
            context: context,
          ),
        ).thenAnswer((_) async {});
        when(
          () => repository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            projectId: any(named: 'projectId'),
            periodType: any(named: 'periodType'),
            scheduleMode: any(named: 'scheduleMode'),
            targetCount: any(named: 'targetCount'),
            scheduleDays: any(named: 'scheduleDays'),
            scheduleMonthDays: any(named: 'scheduleMonthDays'),
            scheduleTimeMinutes: any(named: 'scheduleTimeMinutes'),
            minSpacingDays: any(named: 'minSpacingDays'),
            restDayBuffer: any(named: 'restDayBuffer'),
            isActive: any(named: 'isActive'),
            pausedUntilUtc: any(named: 'pausedUntilUtc'),
            checklistTitles: any(named: 'checklistTitles'),
            context: context,
          ),
        ).thenAnswer((_) async {});
        when(
          () => repository.delete('r1', context: context),
        ).thenAnswer((_) async {});
        when(
          () => repository.recordCompletion(
            routineId: 'r1',
            completedAtUtc: DateTime.utc(2026, 1, 3),
            completedDayLocal: DateTime.utc(2026, 1, 3),
            completedTimeLocalMinutes: 540,
            context: context,
          ),
        ).thenAnswer((_) async {});
        when(
          () => repository.removeLatestCompletionForDay(
            routineId: 'r1',
            dayKeyUtc: DateTime.utc(2026, 1, 3),
            context: context,
          ),
        ).thenAnswer((_) async => true);
        when(
          () => repository.recordSkip(
            routineId: 'r1',
            periodType: RoutineSkipPeriodType.week,
            periodKeyUtc: DateTime.utc(2026, 1, 3),
            context: context,
          ),
        ).thenAnswer((_) async {});

        final createResult = await service.create(
          const CreateRoutineCommand(
            name: 'Routine',
            projectId: 'p1',
            periodType: RoutinePeriodType.week,
            scheduleMode: RoutineScheduleMode.scheduled,
            targetCount: 1,
            scheduleDays: [1],
          ),
          context: context,
        );
        final updateResult = await service.update(
          const UpdateRoutineCommand(
            id: 'r1',
            name: 'Routine',
            projectId: 'p1',
            periodType: RoutinePeriodType.week,
            scheduleMode: RoutineScheduleMode.scheduled,
            targetCount: 1,
            scheduleDays: [1],
          ),
          context: context,
        );
        await service.delete('r1', context: context);
        await service.recordCompletion(
          routineId: 'r1',
          completedAtUtc: DateTime.utc(2026, 1, 3),
          completedDayLocal: DateTime.utc(2026, 1, 3),
          completedTimeLocalMinutes: 540,
          context: context,
        );
        final removed = await service.removeLatestCompletionForDay(
          routineId: 'r1',
          dayKeyUtc: DateTime.utc(2026, 1, 3),
          context: context,
        );
        await service.recordSkip(
          routineId: 'r1',
          periodType: RoutineSkipPeriodType.week,
          periodKeyUtc: DateTime.utc(2026, 1, 3),
          context: context,
        );

        expect(createResult, isA<CommandSuccess>());
        expect(updateResult, isA<CommandSuccess>());
        expect(removed, isTrue);
      },
    );

    testSafe('setPausedUntil returns false when routine is missing', () async {
      when(() => repository.getById('missing')).thenAnswer((_) async => null);
      final ok = await service.setPausedUntil(
        'missing',
        pausedUntilUtc: DateTime.utc(2026, 2, 1),
        context: context,
      );
      expect(ok, isFalse);
    });

    testSafe('setPausedUntil updates routine and returns true', () async {
      final routine = Routine(
        id: 'r1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        name: 'Routine',
        projectId: 'p1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.scheduled,
        targetCount: 1,
        scheduleDays: const [1],
      );
      when(() => repository.getById('r1')).thenAnswer((_) async => routine);
      when(
        () => repository.update(
          id: routine.id,
          name: routine.name,
          projectId: routine.projectId,
          periodType: routine.periodType,
          scheduleMode: routine.scheduleMode,
          targetCount: routine.targetCount,
          scheduleDays: routine.scheduleDays,
          scheduleMonthDays: routine.scheduleMonthDays,
          scheduleTimeMinutes: routine.scheduleTimeMinutes,
          minSpacingDays: routine.minSpacingDays,
          restDayBuffer: routine.restDayBuffer,
          isActive: routine.isActive,
          pausedUntilUtc: DateTime.utc(2026, 2, 1),
          checklistTitles: const <String>[],
          context: context,
        ),
      ).thenAnswer((_) async {});

      final ok = await service.setPausedUntil(
        'r1',
        pausedUntilUtc: DateTime.utc(2026, 2, 1),
        context: context,
      );

      expect(ok, isTrue);
    });
  });

  group('ValueWriteService', () {
    late _MockValueRepository repository;
    late ValueWriteService service;
    final context = const OperationContext(
      correlationId: 'ctx-value',
      feature: 'test',
      intent: 'value',
      operation: 'value.op',
    );

    setUp(() {
      repository = _MockValueRepository();
      service = ValueWriteService(valueRepository: repository);
      when(() => repository.getCount()).thenAnswer((_) async => 0);
    });

    testSafe(
      'create/update/delete/reassign delegate and validate success',
      () async {
        when(
          () => repository.create(
            name: any(named: 'name'),
            color: any(named: 'color'),
            iconName: any(named: 'iconName'),
            priority: any(named: 'priority'),
            context: context,
          ),
        ).thenAnswer((_) async {});
        when(
          () => repository.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            color: any(named: 'color'),
            iconName: any(named: 'iconName'),
            priority: any(named: 'priority'),
            context: context,
          ),
        ).thenAnswer((_) async {});
        when(
          () => repository.delete('v1', context: context),
        ).thenAnswer((_) async {});
        when(
          () => repository.reassignProjectsAndDelete(
            valueId: 'v1',
            replacementValueId: 'v2',
            context: context,
          ),
        ).thenAnswer((_) async => 3);

        final createResult = await service.create(
          const CreateValueCommand(
            name: 'Value',
            color: '#fff',
            priority: ValuePriority.high,
            iconName: 'star',
          ),
          context: context,
        );
        final updateResult = await service.update(
          const UpdateValueCommand(
            id: 'v1',
            name: 'Value',
            color: '#fff',
            priority: ValuePriority.medium,
            iconName: 'star',
          ),
          context: context,
        );
        await service.delete('v1', context: context);
        final moved = await service.reassignProjectsAndDelete(
          valueId: 'v1',
          replacementValueId: 'v2',
          context: context,
        );

        expect(createResult, isA<CommandSuccess>());
        expect(updateResult, isA<CommandSuccess>());
        expect(moved, 3);
      },
    );
  });
}
