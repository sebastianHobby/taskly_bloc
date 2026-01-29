@Tags(['unit', 'projects'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/features/project_picker/bloc/project_picker_bloc.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockSessionSharedDataService sharedDataService;
  late BehaviorSubject<List<Project>> projectsSubject;

  ProjectPickerBloc buildBloc() {
    return ProjectPickerBloc(sharedDataService: sharedDataService);
  }

  setUp(() {
    sharedDataService = MockSessionSharedDataService();
    projectsSubject = BehaviorSubject<List<Project>>();
    when(() => sharedDataService.watchAllProjects()).thenAnswer(
      (_) => projectsSubject.stream,
    );
    addTearDown(projectsSubject.close);
  });

  blocTestSafe<ProjectPickerBloc, ProjectPickerState>(
    'loads and filters projects',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const ProjectPickerStarted());
      projectsSubject.add([
        TestData.project(id: 'p2', name: 'Bravo'),
        TestData.project(id: 'p1', name: 'Alpha'),
      ]);
      bloc.add(const ProjectPickerSearchChanged(query: 'bra'));
    },
    expect: () => [
      const ProjectPickerState.initial().copyWith(isLoading: true),
      isA<ProjectPickerState>().having(
        (s) => s.allProjects.first.name,
        'first',
        'Alpha',
      ),
      isA<ProjectPickerState>()
          .having((s) => s.visibleProjects.length, 'visible', 1)
          .having((s) => s.visibleProjects.first.name, 'name', 'Bravo'),
    ],
  );
}
