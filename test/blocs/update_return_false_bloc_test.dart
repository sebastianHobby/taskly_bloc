import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  late MockTaskRepository mockTaskRepo;
  late MockProjectRepository mockProjectRepo;
  late TaskTableData sampleTask;
  late ProjectTableData sampleProject;

  setUpAll(() {
    registerFallbackValue(TaskTableCompanion(id: const Value('f')));
    registerFallbackValue(ProjectTableCompanion(id: const Value('f')));
  });

  setUp(() {
    mockTaskRepo = MockTaskRepository();
    mockProjectRepo = MockProjectRepository();

    sampleTask = TaskTableData(
      id: 't1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Task 1',
      completed: false,
    );

    sampleProject = ProjectTableData(
      id: 'p1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Project 1',
      completed: false,
    );
  });

  blocTest<TaskOverviewBloc, TaskOverviewState>(
    'toggleTaskCompletion emits error when updateTask throws',
    setUp: () {
      when(
        () => mockTaskRepo.updateTask(any()),
      ).thenAnswer((_) async => throw Exception('update fail'));
    },
    build: () => TaskOverviewBloc(taskRepository: mockTaskRepo),
    act: (bloc) =>
        bloc.add(TaskOverviewEvent.toggleTaskCompletion(taskData: sampleTask)),
    expect: () => <dynamic>[isA<TaskOverviewError>()],
    verify: (_) async {
      verify(() => mockTaskRepo.updateTask(any())).called(1);
    },
  );

  blocTest<ProjectOverviewBloc, ProjectOverviewState>(
    'toggleProjectCompletion emits error when updateProject throws',
    setUp: () {
      when(
        () => mockProjectRepo.updateProject(any()),
      ).thenAnswer((_) async => throw Exception('update fail'));
    },
    build: () => ProjectOverviewBloc(projectRepository: mockProjectRepo),
    act: (bloc) => bloc.add(
      ProjectOverviewEvent.toggleProjectCompletion(projectData: sampleProject),
    ),
    expect: () => <dynamic>[isA<ProjectOverviewError>()],
    verify: (_) async {
      verify(() => mockProjectRepo.updateProject(any())).called(1);
    },
  );
}
