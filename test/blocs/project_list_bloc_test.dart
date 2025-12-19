import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';

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

  blocTest<ProjectOverviewBloc, ProjectOverviewState>(
    'emits loading then loaded when subscriptionRequested and repository provides projects',
    setUp: () {
      when(
        () => mockRepository.getProjects,
      ).thenAnswer((_) => Stream.value([sampleProject]));
    },
    build: () => ProjectOverviewBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(ProjectOverviewSubscriptionRequested()),
    expect: () => <ProjectOverviewState>[
      const ProjectOverviewState.loading(),
      ProjectOverviewState.loaded(projects: [sampleProject]),
    ],
  );

  blocTest<ProjectOverviewBloc, ProjectOverviewState>(
    'toggleProjectCompletion calls repository.updateProject',
    setUp: () {
      when(
        () => mockRepository.updateProject(any()),
      ).thenAnswer((_) async => true);
    },
    build: () => ProjectOverviewBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      ProjectOverviewEvent.toggleProjectCompletion(projectData: sampleProject),
    ),
    expect: () => <ProjectOverviewState>[],
    verify: (_) async {
      verify(() => mockRepository.updateProject(any())).called(1);
    },
  );
}
