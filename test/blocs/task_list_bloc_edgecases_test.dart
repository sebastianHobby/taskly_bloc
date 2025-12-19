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
    registerFallbackValue(TaskTableCompanion(id: const Value('f')));
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
    'subscription emits error state when repository stream errors',
    setUp: () {
      when(() => mockRepository.getTasks).thenAnswer(
        (_) => Stream<List<TaskTableData>>.error(Exception('stream fail')),
      );
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
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
        () => mockRepository.updateTask(any()),
      ).thenThrow(Exception('update fail'));
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
    act: (bloc) =>
        bloc.add(TaskOverviewEvent.toggleTaskCompletion(taskData: sampleTask)),
    expect: () => <dynamic>[
      isA<TaskOverviewError>(),
    ],
  );
}
