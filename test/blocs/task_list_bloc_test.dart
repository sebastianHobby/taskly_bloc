import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_query.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

void main() {
  late MockTaskRepository mockRepository;
  late Task sampleTask;
  late Task completedTask;

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

    completedTask = Task(
      id: 't2',
      createdAt: now,
      updatedAt: now,
      name: 'Task 2',
      completed: true,
    );
  });

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'emits loading then loaded when subscriptionRequested and repository provides tasks',
    setUp: () {
      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.value([sampleTask]));
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      isA<TaskOverviewLoading>(),
      isA<TaskOverviewLoaded>(),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'filterChanged re-emits loaded with filtered tasks',
    setUp: () {
      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.value([sampleTask, completedTask]));
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
    act: (bloc) async {
      bloc.add(const TaskOverviewEvent.subscriptionRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const TaskOverviewEvent.queryChanged(
          query: TaskListQuery(
            completion: TaskCompletionFilter.completed,
          ),
        ),
      );
    },
    expect: () => <TaskOverviewState>[
      const TaskOverviewState.loading(),
      TaskOverviewState.loaded(
        tasks: [sampleTask, completedTask],
        query: TaskListQuery.all,
      ),
      TaskOverviewState.loaded(
        tasks: [completedTask],
        query: const TaskListQuery(
          completion: TaskCompletionFilter.completed,
        ),
      ),
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
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
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
    'today query includes tasks with start date or deadline on/before today',
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

      final taskWithDeadlineTomorrow = Task(
        id: 't5',
        createdAt: now,
        updatedAt: now,
        name: 'C deadline tomorrow',
        completed: false,
        deadlineDate: today.add(const Duration(days: 1)),
      );

      final taskWithoutDates = Task(
        id: 't6',
        createdAt: now,
        updatedAt: now,
        name: 'D no dates',
        completed: false,
      );

      when(
        () => mockRepository.watchAll(),
      ).thenAnswer(
        (_) => Stream.value(
          [
            taskWithDeadlineTomorrow,
            taskWithoutDates,
            taskWithDeadlineToday,
            taskWithStartYesterday,
          ],
        ),
      );
    },
    build: () {
      final now = DateTime(2025, 1, 15, 10, 30);
      return TaskOverviewBloc(
        taskRepository: mockRepository,
        initialQuery: TaskListQuery.today(now: now),
      );
    },
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      const TaskOverviewState.loading(),
      isA<TaskOverviewLoaded>().having(
        (s) => s.tasks.map((t) => t.id).toList(growable: false),
        'task ids',
        ['t3', 't4'],
      ),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'upcoming query includes tasks with start date or deadline on/after tomorrow',
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

      final taskWithDeadlineToday = Task(
        id: 'u3',
        createdAt: now,
        updatedAt: now,
        name: 'C deadline today',
        completed: false,
        deadlineDate: today,
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

      final taskWithoutDates = Task(
        id: 'u5',
        createdAt: now,
        updatedAt: now,
        name: 'E no dates',
        completed: false,
      );

      when(
        () => mockRepository.watchAll(),
      ).thenAnswer(
        (_) => Stream.value(
          [
            taskWithDeadlineToday,
            taskWithoutDates,
            taskWithDeadlineNextWeek,
            taskWithStartYesterdayDeadlineTomorrow,
            taskWithStartTomorrow,
          ],
        ),
      );
    },
    build: () {
      final now = DateTime(2025, 1, 15, 10, 30);
      return TaskOverviewBloc(
        taskRepository: mockRepository,
        initialQuery: TaskListQuery.upcoming(now: now),
      );
    },
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      const TaskOverviewState.loading(),
      isA<TaskOverviewLoaded>().having(
        (s) => s.tasks.map((t) => t.id).toList(growable: false),
        'task ids',
        ['u1', 'u2', 'u4'],
      ),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'projectId query includes only tasks linked to project',
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

      final p2Task = Task(
        id: 'p2t1',
        createdAt: now,
        updatedAt: now,
        name: 'B other project task',
        completed: false,
        projectId: 'p2',
      );

      final noProjectTask = Task(
        id: 'np1',
        createdAt: now,
        updatedAt: now,
        name: 'C no project',
        completed: false,
      );

      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.value([p2Task, noProjectTask, p1Task]));
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      initialQuery: const TaskListQuery(projectId: 'p1'),
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
    'labelId query includes only tasks linked to label',
    setUp: () {
      final now = DateTime(2025, 1, 15, 10, 30);

      final l1 = Label(id: 'l1', createdAt: now, updatedAt: now, name: 'L1');
      final l2 = Label(id: 'l2', createdAt: now, updatedAt: now, name: 'L2');

      final a = Task(
        id: 'lt1',
        createdAt: now,
        updatedAt: now,
        name: 'A label task',
        completed: false,
        labels: [l1],
      );

      final b = Task(
        id: 'lt2',
        createdAt: now,
        updatedAt: now,
        name: 'B other label task',
        completed: false,
        labels: [l2],
      );

      when(
        () => mockRepository.watchAll(withRelated: true),
      ).thenAnswer((_) => Stream.value([b, a]));
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      initialQuery: const TaskListQuery(labelId: 'l1'),
      withRelated: true,
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
