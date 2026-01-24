@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class _MockTaskRepo extends Mock implements TaskRepositoryContract {}

class _MockProjectRepo extends Mock implements ProjectRepositoryContract {}

class _FakeDayKeyService extends Fake implements HomeDayKeyService {
  _FakeDayKeyService(this._dayKeyUtc);

  DateTime _dayKeyUtc;

  void setDay(DateTime dayKeyUtc) {
    _dayKeyUtc = dayKeyUtc;
  }

  @override
  DateTime todayDayKeyUtc({DateTime? nowUtc}) {
    final resolved = nowUtc ?? _dayKeyUtc;
    return dateOnly(resolved);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2000, 1, 1));
    registerFallbackValue(TaskQuery.all());
    registerFallbackValue(ProjectQuery.all());
  });

  Task baseTask({
    required String id,
    bool repeating = false,
    bool seriesEnded = false,
    bool completed = false,
  }) {
    return Task(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Task $id',
      completed: completed,
      repeatIcalRrule: repeating ? 'RRULE:FREQ=DAILY' : null,
      seriesEnded: seriesEnded,
    );
  }

  Project baseProject({
    required String id,
    bool repeating = false,
    bool seriesEnded = false,
    bool completed = false,
  }) {
    return Project(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Project $id',
      completed: completed,
      repeatIcalRrule: repeating ? 'RRULE:FREQ=DAILY' : null,
      seriesEnded: seriesEnded,
    );
  }

  Task occurrenceTask({
    required String id,
    required DateTime date,
    DateTime? originalDate,
    String? completionId,
  }) {
    return baseTask(id: id, repeating: true).copyWith(
      occurrence: OccurrenceData(
        date: date,
        originalDate: originalDate,
        isRescheduled: originalDate != null,
        completionId: completionId,
      ),
    );
  }

  Project occurrenceProject({
    required String id,
    required DateTime date,
    DateTime? originalDate,
    String? completionId,
  }) {
    return baseProject(id: id, repeating: true).copyWith(
      occurrence: OccurrenceData(
        date: date,
        originalDate: originalDate,
        isRescheduled: originalDate != null,
        completionId: completionId,
      ),
    );
  }

  testSafe('completeTask uses provided occurrence date', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(
      () => taskRepo.completeOccurrence(
        taskId: any(named: 'taskId'),
        occurrenceDate: any(named: 'occurrenceDate'),
        originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
        notes: any(named: 'notes'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    final occurrenceDate = DateTime.utc(2026, 1, 11);
    await service.completeTask(
      taskId: 't1',
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: DateTime.utc(2026, 1, 9),
    );

    verify(
      () => taskRepo.completeOccurrence(
        taskId: 't1',
        occurrenceDate: occurrenceDate,
        originalOccurrenceDate: DateTime.utc(2026, 1, 9),
        notes: null,
        context: null,
      ),
    ).called(1);
    verifyNever(() => taskRepo.getById(any()));
  });

  testSafe(
    'completeTask completes non-repeating task as single entity',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => taskRepo.getById('t2'),
      ).thenAnswer((_) async => baseTask(id: 't2'));
      when(
        () => taskRepo.completeOccurrence(
          taskId: any(named: 'taskId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
          notes: any(named: 'notes'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      await service.completeTask(taskId: 't2');

      verify(
        () => taskRepo.completeOccurrence(
          taskId: 't2',
          occurrenceDate: null,
          originalOccurrenceDate: null,
          notes: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe(
    'completeTask resolves next uncompleted occurrence for repeating',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(() => taskRepo.getById('t3')).thenAnswer(
        (_) async => baseTask(id: 't3', repeating: true),
      );
      when(
        () => taskRepo.getOccurrencesForTask(
          taskId: 't3',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => <Task>[
          occurrenceTask(
            id: 't3',
            date: DateTime.utc(2026, 1, 9),
            completionId: null,
          ),
          occurrenceTask(
            id: 't3',
            date: DateTime.utc(2026, 1, 12),
            originalDate: DateTime.utc(2026, 1, 11),
            completionId: null,
          ),
        ],
      );
      when(
        () => taskRepo.completeOccurrence(
          taskId: any(named: 'taskId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
          notes: any(named: 'notes'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      await service.completeTask(taskId: 't3');

      verify(
        () => taskRepo.completeOccurrence(
          taskId: 't3',
          occurrenceDate: DateTime.utc(2026, 1, 12),
          originalOccurrenceDate: DateTime.utc(2026, 1, 11),
          notes: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe('uncompleteTask uses most recent completed occurrence', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => taskRepo.getById('t4')).thenAnswer(
      (_) async => baseTask(id: 't4', repeating: true),
    );
    when(
      () => taskRepo.getOccurrencesForTask(
        taskId: 't4',
        rangeStart: any(named: 'rangeStart'),
        rangeEnd: any(named: 'rangeEnd'),
      ),
    ).thenAnswer(
      (_) async => <Task>[
        occurrenceTask(
          id: 't4',
          date: DateTime.utc(2026, 1, 8),
          completionId: 'c1',
        ),
        occurrenceTask(
          id: 't4',
          date: DateTime.utc(2026, 1, 12),
          completionId: 'c2',
        ),
      ],
    );
    when(
      () => taskRepo.uncompleteOccurrence(
        taskId: any(named: 'taskId'),
        occurrenceDate: any(named: 'occurrenceDate'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await service.uncompleteTask(taskId: 't4');

    verify(
      () => taskRepo.uncompleteOccurrence(
        taskId: 't4',
        occurrenceDate: DateTime.utc(2026, 1, 8),
        context: null,
      ),
    ).called(1);
  });

  testSafe('completeTaskSeries marks task completed and ended', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    final task =
        baseTask(
          id: 't5',
          repeating: true,
        ).copyWith(
          description: 'Desc',
          startDate: DateTime.utc(2026, 1, 1),
          deadlineDate: DateTime.utc(2026, 1, 3),
          repeatFromCompletion: true,
          isPinned: true,
        );

    when(() => taskRepo.getById('t5')).thenAnswer((_) async => task);
    when(
      () => taskRepo.update(
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
        isPinned: any(named: 'isPinned'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await service.completeTaskSeries(taskId: 't5');

    verify(
      () => taskRepo.update(
        id: 't5',
        name: task.name,
        completed: true,
        description: task.description,
        startDate: task.startDate,
        deadlineDate: task.deadlineDate,
        projectId: task.projectId,
        priority: task.priority,
        repeatIcalRrule: task.repeatIcalRrule,
        repeatFromCompletion: task.repeatFromCompletion,
        seriesEnded: true,
        isPinned: task.isPinned,
        context: null,
      ),
    ).called(1);
  });

  testSafe('completeProject resolves next uncompleted occurrence', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => projectRepo.getById('p1')).thenAnswer(
      (_) async => baseProject(id: 'p1', repeating: true),
    );
    when(
      () => projectRepo.getOccurrencesForProject(
        projectId: 'p1',
        rangeStart: any(named: 'rangeStart'),
        rangeEnd: any(named: 'rangeEnd'),
      ),
    ).thenAnswer(
      (_) async => <Project>[
        occurrenceProject(
          id: 'p1',
          date: DateTime.utc(2026, 1, 10),
          completionId: null,
        ),
      ],
    );
    when(
      () => projectRepo.completeOccurrence(
        projectId: any(named: 'projectId'),
        occurrenceDate: any(named: 'occurrenceDate'),
        originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
        notes: any(named: 'notes'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await service.completeProject(projectId: 'p1');

    verify(
      () => projectRepo.completeOccurrence(
        projectId: 'p1',
        occurrenceDate: DateTime.utc(2026, 1, 10),
        originalOccurrenceDate: DateTime.utc(2026, 1, 10),
        notes: null,
        context: null,
      ),
    ).called(1);
  });

  testSafe(
    'uncompleteProject uses null occurrence for non-repeating',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => projectRepo.getById('p2'),
      ).thenAnswer((_) async => baseProject(id: 'p2'));
      when(
        () => projectRepo.uncompleteOccurrence(
          projectId: any(named: 'projectId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      await service.uncompleteProject(projectId: 'p2');

      verify(
        () => projectRepo.uncompleteOccurrence(
          projectId: 'p2',
          occurrenceDate: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe('completeProjectSeries updates project with seriesEnded', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    final project = baseProject(id: 'p3', repeating: true).copyWith(
      description: 'Desc',
      startDate: DateTime.utc(2026, 1, 1),
      deadlineDate: DateTime.utc(2026, 1, 3),
      repeatFromCompletion: true,
      priority: 2,
      isPinned: true,
      values: const <Value>[],
    );

    when(() => projectRepo.getById('p3')).thenAnswer((_) async => project);
    when(
      () => projectRepo.update(
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
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await service.completeProjectSeries(projectId: 'p3');

    verify(
      () => projectRepo.update(
        id: 'p3',
        name: project.name,
        completed: true,
        description: project.description,
        startDate: project.startDate,
        deadlineDate: project.deadlineDate,
        repeatIcalRrule: project.repeatIcalRrule,
        repeatFromCompletion: project.repeatFromCompletion,
        seriesEnded: true,
        valueIds: project.values.map((v) => v.id).toList(growable: false),
        priority: project.priority,
        isPinned: project.isPinned,
        context: null,
      ),
    ).called(1);
  });
}
