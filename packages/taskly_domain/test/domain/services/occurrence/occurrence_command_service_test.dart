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

  testSafe('completeTask throws when task is missing', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => taskRepo.getById('missing')).thenAnswer((_) async => null);

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await expectLater(
      () => service.completeTask(taskId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });

  testSafe(
    'completeTask uses single-entity path when series is ended',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => taskRepo.getById('ended'),
      ).thenAnswer(
        (_) async => baseTask(id: 'ended', repeating: true, seriesEnded: true),
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

      await service.completeTask(taskId: 'ended');

      verify(
        () => taskRepo.completeOccurrence(
          taskId: 'ended',
          occurrenceDate: null,
          originalOccurrenceDate: null,
          notes: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe(
    'uncompleteTask throws when no completed occurrences exist',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => taskRepo.getById('t-empty'),
      ).thenAnswer((_) async => baseTask(id: 't-empty', repeating: true));
      when(
        () => taskRepo.getOccurrencesForTask(
          taskId: 't-empty',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => <Task>[
          occurrenceTask(id: 't-empty', date: DateTime.utc(2026, 1, 9)),
        ],
      );

      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      await expectLater(
        () => service.uncompleteTask(taskId: 't-empty'),
        throwsA(isA<StateError>()),
      );
    },
  );

  testSafe('uncompleteTask with explicit occurrence bypasses lookup', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));
    final occurrenceDate = DateTime.utc(2026, 1, 11);

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

    await service.uncompleteTask(taskId: 't1', occurrenceDate: occurrenceDate);

    verify(
      () => taskRepo.uncompleteOccurrence(
        taskId: 't1',
        occurrenceDate: occurrenceDate,
        context: null,
      ),
    ).called(1);
    verifyNever(() => taskRepo.getById(any()));
  });

  testSafe('completeProject throws when project is missing', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => projectRepo.getById('missing')).thenAnswer((_) async => null);

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await expectLater(
      () => service.completeProject(projectId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });

  testSafe(
    'completeProject uses single-entity path when series ended',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => projectRepo.getById('p-ended'),
      ).thenAnswer(
        (_) async =>
            baseProject(id: 'p-ended', repeating: true, seriesEnded: true),
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

      await service.completeProject(projectId: 'p-ended');

      verify(
        () => projectRepo.completeOccurrence(
          projectId: 'p-ended',
          occurrenceDate: null,
          originalOccurrenceDate: null,
          notes: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe(
    'uncompleteProject throws when no completed occurrence exists',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => projectRepo.getById('p-empty'),
      ).thenAnswer((_) async => baseProject(id: 'p-empty', repeating: true));
      when(
        () => projectRepo.getOccurrencesForProject(
          projectId: 'p-empty',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => <Project>[
          occurrenceProject(id: 'p-empty', date: DateTime.utc(2026, 1, 10)),
        ],
      );

      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      await expectLater(
        () => service.uncompleteProject(projectId: 'p-empty'),
        throwsA(isA<StateError>()),
      );
    },
  );

  testSafe(
    'uncompleteProject falls back to latest when all are after asOf',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => projectRepo.getById('p-fallback'),
      ).thenAnswer((_) async => baseProject(id: 'p-fallback', repeating: true));
      when(
        () => projectRepo.getOccurrencesForProject(
          projectId: 'p-fallback',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => <Project>[
          occurrenceProject(
            id: 'p-fallback',
            date: DateTime.utc(2026, 1, 12),
            completionId: 'c1',
          ),
          occurrenceProject(
            id: 'p-fallback',
            date: DateTime.utc(2026, 1, 14),
            completionId: 'c2',
          ),
        ],
      );
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

      await service.uncompleteProject(projectId: 'p-fallback');

      verify(
        () => projectRepo.uncompleteOccurrence(
          projectId: 'p-fallback',
          occurrenceDate: DateTime.utc(2026, 1, 14),
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe(
    'uncompleteTask uses null occurrence for non-repeating task',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(() => taskRepo.getById('t-nr')).thenAnswer(
        (_) async => baseTask(id: 't-nr', repeating: false),
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

      await service.uncompleteTask(taskId: 't-nr');

      verify(
        () => taskRepo.uncompleteOccurrence(
          taskId: 't-nr',
          occurrenceDate: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe('uncompleteTask throws when task is missing', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => taskRepo.getById('missing')).thenAnswer((_) async => null);

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await expectLater(
      () => service.uncompleteTask(taskId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });

  testSafe(
    'completeTask throws when repeating task has no next uncompleted occurrence',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(() => taskRepo.getById('t-no-next')).thenAnswer(
        (_) async => baseTask(id: 't-no-next', repeating: true),
      );
      when(
        () => taskRepo.getOccurrencesForTask(
          taskId: 't-no-next',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => <Task>[
          occurrenceTask(
            id: 't-no-next',
            date: DateTime.utc(2026, 1, 9),
            completionId: 'done-1',
          ),
        ],
      );

      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      await expectLater(
        () => service.completeTask(taskId: 't-no-next'),
        throwsA(isA<StateError>()),
      );
    },
  );

  testSafe(
    'uncompleteTask falls back to latest when all completed are after asOf',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(() => taskRepo.getById('t-fallback')).thenAnswer(
        (_) async => baseTask(id: 't-fallback', repeating: true),
      );
      when(
        () => taskRepo.getOccurrencesForTask(
          taskId: 't-fallback',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => <Task>[
          occurrenceTask(
            id: 't-fallback',
            date: DateTime.utc(2026, 1, 12),
            completionId: 'c1',
          ),
          occurrenceTask(
            id: 't-fallback',
            date: DateTime.utc(2026, 1, 13),
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

      await service.uncompleteTask(taskId: 't-fallback');

      verify(
        () => taskRepo.uncompleteOccurrence(
          taskId: 't-fallback',
          occurrenceDate: DateTime.utc(2026, 1, 13),
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe('completeProject uses provided occurrence date', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));
    final occurrenceDate = DateTime.utc(2026, 1, 11);

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

    await service.completeProject(
      projectId: 'p-raw',
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: DateTime.utc(2026, 1, 9),
    );

    verify(
      () => projectRepo.completeOccurrence(
        projectId: 'p-raw',
        occurrenceDate: occurrenceDate,
        originalOccurrenceDate: DateTime.utc(2026, 1, 9),
        notes: null,
        context: null,
      ),
    ).called(1);
    verifyNever(() => projectRepo.getById(any()));
  });

  testSafe(
    'completeProject completes non-repeating project as single entity',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(
        () => projectRepo.getById('p-nr'),
      ).thenAnswer((_) async => baseProject(id: 'p-nr', repeating: false));
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

      await service.completeProject(projectId: 'p-nr');

      verify(
        () => projectRepo.completeOccurrence(
          projectId: 'p-nr',
          occurrenceDate: null,
          originalOccurrenceDate: null,
          notes: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe(
    'completeProject throws when repeating project has no next uncompleted occurrence',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

      when(() => projectRepo.getById('p-no-next')).thenAnswer(
        (_) async => baseProject(id: 'p-no-next', repeating: true),
      );
      when(
        () => projectRepo.getOccurrencesForProject(
          projectId: 'p-no-next',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => <Project>[
          occurrenceProject(
            id: 'p-no-next',
            date: DateTime.utc(2026, 1, 9),
            completionId: 'done-1',
          ),
        ],
      );

      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      await expectLater(
        () => service.completeProject(projectId: 'p-no-next'),
        throwsA(isA<StateError>()),
      );
    },
  );

  testSafe('uncompleteProject uses explicit occurrence date', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));
    final occurrenceDate = DateTime.utc(2026, 1, 15);

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

    await service.uncompleteProject(
      projectId: 'p-1',
      occurrenceDate: occurrenceDate,
    );

    verify(
      () => projectRepo.uncompleteOccurrence(
        projectId: 'p-1',
        occurrenceDate: occurrenceDate,
        context: null,
      ),
    ).called(1);
    verifyNever(() => projectRepo.getById(any()));
  });

  testSafe('uncompleteProject throws when project is missing', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => projectRepo.getById('missing')).thenAnswer((_) async => null);

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await expectLater(
      () => service.uncompleteProject(projectId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });

  testSafe('completeTaskSeries throws when task is missing', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => taskRepo.getById('missing')).thenAnswer((_) async => null);

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await expectLater(
      () => service.completeTaskSeries(taskId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });

  testSafe('completeProjectSeries throws when project is missing', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final dayKeyService = _FakeDayKeyService(DateTime.utc(2026, 1, 10));

    when(() => projectRepo.getById('missing')).thenAnswer((_) async => null);

    final service = OccurrenceCommandService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      dayKeyService: dayKeyService,
    );

    await expectLater(
      () => service.completeProjectSeries(projectId: 'missing'),
      throwsA(isA<StateError>()),
    );
  });
}
