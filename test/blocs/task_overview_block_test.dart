import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

void main() {
  late MockTaskRepository mockRepository;
  late Task sampleTask;

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
    'emits loading then loaded when subscriptionRequested and repository provides no tasks',
    setUp: () {
      when(() => mockRepository.watchAll()).thenAnswer((_) => Stream.value([]));
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <TaskOverviewState>[
      const TaskOverviewState.loading(),
      TaskOverviewState.loaded(tasks: []),
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
          valueIds: any(named: 'valueIds'),
          labelIds: any(named: 'labelIds'),
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
}
