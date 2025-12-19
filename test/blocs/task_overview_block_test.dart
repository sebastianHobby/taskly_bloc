import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late TaskTableData sampleTask;

  setUpAll(() {
    registerFallbackValue(TaskTableCompanion(id: const Value('fallback')));
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    sampleTask = TaskTableData(
      id: 't1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Task 1',
      completed: false,
    );
  });

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'emits loading then loaded when subscriptionRequested and repository provides tasks',
    setUp: () {
      when(
        () => mockRepository.getTasks,
      ).thenAnswer((_) => Stream.value([sampleTask]));
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
    act: (bloc) => bloc.add(const TaskOverviewEvent.subscriptionRequested()),
    expect: () => <TaskOverviewState>[
      const TaskOverviewState.loading(),
      TaskOverviewState.loaded(tasks: [sampleTask]),
    ],
  );

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'emits loading then loaded when subscriptionRequested and repository provides no tasks',
    setUp: () {
      when(
        () => mockRepository.getTasks,
      ).thenAnswer((_) => Stream.value([]));
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
        () => mockRepository.updateTask(any()),
      ).thenAnswer((_) async => true);
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
    act: (bloc) =>
        bloc.add(TaskOverviewEvent.toggleTaskCompletion(taskData: sampleTask)),
    expect: () => <TaskOverviewState>[],
    verify: (_) async {
      verify(() => mockRepository.updateTask(any())).called(1);
    },
  );
}
