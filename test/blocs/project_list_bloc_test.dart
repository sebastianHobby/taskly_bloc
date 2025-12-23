import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/projects/bloc/project_list_bloc.dart';

import '../mocks/repository_mocks.dart';

void main() {
  late MockProjectRepository mockRepository;
  late Project sampleProject;

  setUp(() {
    mockRepository = MockProjectRepository();
    final now = DateTime.now();
    sampleProject = Project(
      id: 'p1',
      createdAt: now,
      updatedAt: now,
      name: 'Project 1',
      completed: false,
    );
  });

  blocTest<ProjectOverviewBloc, ProjectOverviewState>(
    'emits loading then loaded when subscriptionRequested and repository provides projects',
    setUp: () {
      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.value([sampleProject]));
    },
    build: () => ProjectOverviewBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(const ProjectOverviewEvent.subscriptionRequested()),
    expect: () => <Object>[
      isA<ProjectOverviewLoading>(),
      isA<ProjectOverviewLoaded>(),
    ],
  );

  blocTest<ProjectOverviewBloc, ProjectOverviewState>(
    'toggleProjectCompletion calls repository.updateProject',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => ProjectOverviewBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      ProjectOverviewEvent.toggleProjectCompletion(
        project: sampleProject,
      ),
    ),
    expect: () => <ProjectOverviewState>[],
    verify: (_) async {
      verify(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).called(1);
    },
  );
}
