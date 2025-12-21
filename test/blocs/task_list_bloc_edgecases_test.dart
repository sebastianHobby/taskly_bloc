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
    'subscription emits error state when repository stream errors',
    setUp: () {
      when(() => mockRepository.watchAll()).thenAnswer(
        (_) => Stream<List<Task>>.error(Exception('stream fail')),
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
      ).thenThrow(Exception('update fail'));
    },
    build: () => TaskOverviewBloc(taskRepository: mockRepository),
    act: (bloc) => bloc.add(
      TaskOverviewEvent.toggleTaskCompletion(task: sampleTask),
    ),
    expect: () => <dynamic>[
      isA<TaskOverviewError>(),
    ],
  );
}
