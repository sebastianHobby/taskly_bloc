import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  late MockProjectRepository mockRepository;
  late ProjectTableData sampleProject;

  setUpAll(() {
    registerFallbackValue(ProjectTableCompanion(id: const Value('f')));
  });

  setUp(() {
    mockRepository = MockProjectRepository();
    sampleProject = ProjectTableData(
      id: 'p1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Project 1',
      completed: false,
    );
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a project',
    setUp: () {
      when(
        () => mockRepository.getProjectById('p1'),
      ).thenAnswer((_) async => sampleProject);
    },
    build: () =>
        ProjectDetailBloc(projectRepository: mockRepository, projectId: 'p1'),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.loadInProgress(),
      ProjectDetailState.loadSuccess(project: sampleProject),
    ],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'create emits operationSuccess on successful create',
    setUp: () {
      when(
        () => mockRepository.createProject(any()),
      ).thenAnswer((_) async => 1);
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.create(name: 'n', description: 'null'),
    ),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.operationSuccess(
        message: 'Project created successfully.',
      ),
    ],
  );
}
