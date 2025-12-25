import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';

import '../mocks/repository_mocks.dart';

class _FakeTaskQuery extends Fake implements TaskQuery {}

void main() {
  late MockTaskRepository mockRepository;
  late Task sampleTask;

  setUpAll(() {
    registerFallbackValue(_FakeTaskQuery());
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    final now = DateTime.now();
    sampleTask = Task(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      name: 'Task 1',
      completed: false,
    );
  });

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'emits loading then loaded when subscriptionRequested and repository provides tasks',
    setUp: () {
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([sampleTask]));
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      query: TaskQuery.all(),
    ),
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      isA<TaskOverviewLoading>(),
      isA<TaskOverviewLoaded>(),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'toggleTaskCompletion calls repository.updateTask',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      query: TaskQuery.all(),
    ),
    act: (bloc) => bloc.add(
      TaskOverviewEvent.toggleTaskCompletion(task: sampleTask),
    ),
    expect: () => <TaskOverviewState>[],
    verify: (_) async {
      verify(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
        ),
      ).called(1);
    },
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'today query returns filtered tasks from repository',
    setUp: () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final today = DateTime(now.year, now.month, now.day);

      final taskWithStartYesterday = Task(
        id: 't3',
        createdAt: now,
        updatedAt: now,
        name: 'A start yesterday',
        completed: false,
        startDate: today.subtract(const Duration(days: 1)),
      );

      final taskWithDeadlineToday = Task(
        id: 't4',
        createdAt: now,
        updatedAt: now,
        name: 'B deadline today',
        completed: false,
        deadlineDate: today,
      );

      // Repository returns already-filtered results based on query
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer(
        (_) => Stream.value([taskWithDeadlineToday, taskWithStartYesterday]),
      );
    },
    build: () {
      final now = DateTime(2025, 1, 15, 10, 30);
      return TaskOverviewBloc(
        taskRepository: mockRepository,
        query: TaskQuery.today(now: now),
      );
    },
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      const TaskOverviewState.loading(),
      isA<TaskOverviewLoaded>().having(
        (s) => s.tasks.map((t) => t.id).toList(growable: false),
        'task ids',
        ['t4', 't3'],
      ),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'upcoming query returns filtered tasks from repository',
    setUp: () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final taskWithStartTomorrow = Task(
        id: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'A start tomorrow',
        completed: false,
        startDate: tomorrow,
      );

      final taskWithDeadlineNextWeek = Task(
        id: 'u2',
        createdAt: now,
        updatedAt: now,
        name: 'B deadline next week',
        completed: false,
        deadlineDate: tomorrow.add(const Duration(days: 7)),
      );

      final taskWithStartYesterdayDeadlineTomorrow = Task(
        id: 'u4',
        createdAt: now,
        updatedAt: now,
        name: 'D start yesterday deadline tomorrow',
        completed: false,
        startDate: today.subtract(const Duration(days: 1)),
        deadlineDate: tomorrow,
      );

      // Repository returns already-filtered results based on query
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer(
        (_) => Stream.value([
          taskWithStartYesterdayDeadlineTomorrow,
          taskWithDeadlineNextWeek,
          taskWithStartTomorrow,
        ]),
      );
    },
    build: () {
      return TaskOverviewBloc(
        taskRepository: mockRepository,
        query: TaskQuery.upcoming(),
      );
    },
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      const TaskOverviewState.loading(),
      isA<TaskOverviewLoaded>().having(
        (s) => s.tasks.map((t) => t.id).toList(growable: false),
        'task ids',
        ['u4', 'u2', 'u1'],
      ),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'projectId query returns filtered tasks from repository',
    setUp: () {
      final now = DateTime(2025, 1, 15, 10, 30);

      final p1Task = Task(
        id: 'p1t1',
        createdAt: now,
        updatedAt: now,
        name: 'A project task',
        completed: false,
        projectId: 'p1',
      );

      // Repository returns already-filtered results based on query
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([p1Task]));
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      query: TaskQuery.forProject(projectId: 'p1'),
    ),
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      const TaskOverviewState.loading(),
      isA<TaskOverviewLoaded>().having(
        (s) => s.tasks.map((t) => t.id).toList(growable: false),
        'task ids',
        ['p1t1'],
      ),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'labelId query returns filtered tasks from repository',
    setUp: () {
      final now = DateTime(2025, 1, 15, 10, 30);

      final l1 = Label(id: 'l1', createdAt: now, updatedAt: now, name: 'L1');

      final a = Task(
        id: 'lt1',
        createdAt: now,
        updatedAt: now,
        name: 'A label task',
        completed: false,
        labels: [l1],
      );

      // Repository returns already-filtered results based on query
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([a]));
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      query: TaskQuery.forLabel(labelId: 'l1'),
    ),
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      const TaskOverviewState.loading(),
      isA<TaskOverviewLoaded>().having(
        (s) => s.tasks.map((t) => t.id).toList(growable: false),
        'task ids',
        ['lt1'],
      ),
    ],
  );
}
