import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

void main() {
  late MockTaskRepository mockTaskRepo;
  late MockProjectRepository mockProjectRepo;
  late Task sampleTask;
  late Project sampleProject;

  setUp(() {
    mockTaskRepo = MockTaskRepository();
    mockProjectRepo = MockProjectRepository();

    final now = DateTime.now();
    sampleTask = Task(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      name: 'Task 1',
      completed: false,
    );

    sampleProject = Project(
      id: 'p1',
      createdAt: now,
      updatedAt: now,
      name: 'Project 1',
      completed: false,
    );
  });

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'toggleTaskCompletion emits error when updateTask throws',
    setUp: () {
      when(
        () => mockTaskRepo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
        ),
      ).thenAnswer((_) async => throw Exception('update fail'));
    },
    build: () => TaskOverviewBloc(taskRepository: mockTaskRepo),
    act: (bloc) => bloc.add(
      TaskOverviewEvent.toggleTaskCompletion(task: sampleTask),
    ),
    expect: () => <dynamic>[isA<TaskOverviewError>()],
    verify: (_) async {
      verify(
        () => mockTaskRepo.update(
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

  blocTest<ProjectOverviewBloc, ProjectOverviewState>(
    'toggleProjectCompletion emits error when updateProject throws',
    setUp: () {
      when(
        () => mockProjectRepo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async => throw Exception('update fail'));
    },
    build: () => ProjectOverviewBloc(projectRepository: mockProjectRepo),
    act: (bloc) => bloc.add(
      ProjectOverviewEvent.toggleProjectCompletion(
        project: sampleProject,
      ),
    ),
    expect: () => <dynamic>[isA<ProjectOverviewError>()],
    verify: (_) async {
      verify(
        () => mockProjectRepo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).called(1);
    },
  );
}
