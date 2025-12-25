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
    'subscription emits error state when repository stream errors',
    setUp: () {
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer(
        (_) => Stream<List<Task>>.error(Exception('stream fail')),
      );
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      query: TaskQuery.all(),
    ),
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <dynamic>[
      const TaskOverviewState.loading(),
      isA<TaskOverviewError>(),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'toggleTaskCompletion emits error state when updateTask throws',
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
      ).thenThrow(Exception('update fail'));
    },
    build: () => TaskOverviewBloc(
      taskRepository: mockRepository,
      query: TaskQuery.all(),
    ),
    act: (bloc) => bloc.add(
      TaskOverviewEvent.toggleTaskCompletion(task: sampleTask),
    ),
    expect: () => <dynamic>[
      isA<TaskOverviewError>(),
    ],
  );
}
